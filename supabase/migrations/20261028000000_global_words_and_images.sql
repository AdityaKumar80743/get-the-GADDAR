-- ============================================================================
-- 1. ADD SECRET_IMAGE_URL TO ROOMS TABLE
-- ============================================================================
alter table public.rooms add column if not exists secret_image_url text;

-- ============================================================================
-- 2. CREATE GLOBAL_WORDS TABLE (Multiple Hints & Optional Image URL)
-- ============================================================================
create table if not exists public.global_words (
  id uuid primary key default gen_random_uuid(),
  category text not null,
  word text not null,
  hints text[] not null default '{}',
  image_url text,
  created_at timestamptz not null default now()
);

-- Enable Supabase Realtime & Row Level Security
alter publication supabase_realtime add table public.global_words;
alter table public.global_words enable row level security;

-- Policies for public guest / local admin tool access
drop policy if exists "Allow public select on global_words" on public.global_words;
create policy "Allow public select on global_words" on public.global_words for select using (true);

drop policy if exists "Allow public insert on global_words" on public.global_words;
create policy "Allow public insert on global_words" on public.global_words for insert with check (true);

drop policy if exists "Allow public update on global_words" on public.global_words;
create policy "Allow public update on global_words" on public.global_words for update using (true) with check (true);

drop policy if exists "Allow public delete on global_words" on public.global_words;
create policy "Allow public delete on global_words" on public.global_words for delete using (true);

-- ============================================================================
-- 3. UPDATE START_MATCH RPC TO SUPPORT OPTIONAL SECRET IMAGE URL
-- ============================================================================
-- Drop legacy 5-parameter version so PostgREST resolves the function unambiguously
drop function if exists public.start_match(uuid, text, text, text, uuid[]);

create or replace function public.start_match(
  p_room_id uuid,
  p_secret_word text,
  p_secret_hint text,
  p_secret_category text,
  p_gaddar_ids uuid[],
  p_secret_image_url text default null
)
returns void
language plpgsql
security definer
as $$
begin
  -- Reset all players in room for new match
  update public.players
  set role = case when id = any(p_gaddar_ids) then 'gaddar' else 'friend' end,
      is_eliminated = false,
      has_ready = false,
      has_voted_current_round = false,
      secret_score = 0,
      correct_gaddar_votes = 0,
      rounds_survived_as_gaddar = 0
  where room_id = p_room_id;

  -- Clear prior votes for this room
  delete from public.votes where room_id = p_room_id;

  -- Move room to role_reveal phase
  update public.rooms
  set status = 'role_reveal',
      current_round = 1,
      secret_word = p_secret_word,
      secret_hint = p_secret_hint,
      secret_category = p_secret_category,
      secret_image_url = p_secret_image_url,
      caught_gaddar_id = null,
      caught_gaddar_name = null,
      last_chance_guess = null,
      winner_team = null,
      win_reason = null,
      phase_started_at = now()
  where id = p_room_id;
end;
$$;

-- ============================================================================
-- 4. PRE-POPULATE INITIAL GLOBAL WORDS WITH MULTIPLE HINTS & IMAGES
-- ============================================================================
insert into public.global_words (category, word, hints, image_url)
values
  (
    'Cricket',
    'MS Dhoni',
    array['Helicopter Shot Finisher', 'Number 7 Jersey Icon', 'Ranchi Ticket Collector', 'CSK Thala Captain', 'Stump Mic Mastermind'],
    'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=600'
  ),
  (
    'Cricket',
    'Virat Kohli',
    array['King of Run Chases', 'Signature Cover Drive', 'Aggressive Century Roar', 'Number 18 Test Captain'],
    'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=600'
  ),
  (
    'Cricket',
    'Yorker',
    array['Toe-Crushing Fast Delivery', 'Base of the Off Stump', 'Death Overs Lethal Weapon', 'Lasith Malinga Signature'],
    null
  ),
  (
    'Movies',
    'Sholay',
    array['Classic Coin Toss', 'Gabbar Laugh in Ramgarh', 'Kitne Aadmi The Dialogue', 'Basanti Dancing on Glass'],
    'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=600'
  ),
  (
    'Movies',
    '3 Idiots',
    array['Imperial College of Engineering', 'All Is Well Motto', 'Silencer Speech Roast', 'Virus Professor Drone'],
    'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?w=600'
  ),
  (
    'Movies',
    'Bahubali',
    array['Royal Waterfall Jump', 'Katappa Shocking Betrayal', 'Mahishmati Empire Throne', 'Golden Bow Triple Arrow'],
    'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600'
  ),
  (
    'Anime',
    'Naruto Uzumaki',
    array['Orange Jumpsuit Ninja', 'Ichiraku Ramen Addiction', 'Nine-Tailed Fox Beast', 'Shadow Clone Rasengan'],
    'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600'
  ),
  (
    'Anime',
    'Death Note',
    array['Black Ruled Notebook', 'Shinigami Loves Red Apples', 'Genius Detective L Sugar Cubes', 'Write a Name in 40 Seconds'],
    null
  ),
  (
    'Anime',
    'Gojo Satoru',
    array['Blindfolded White Hair Sorcerer', 'Limitless Infinity Void', 'Hollow Technique Purple', 'Jujutsu High Strongest Teacher'],
    null
  ),
  (
    'Indian Food',
    'Pani Puri',
    array['Crispy Hollow Semolina Sphere', 'Spicy Mint Tamarind Water', 'Street Vendor Quick Refills', 'Golgappa / Phuchka Nickname'],
    'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=600'
  ),
  (
    'Indian Food',
    'Hyderabadi Biryani',
    array['Slow-Cooked Dum Clay Handi', 'Fragrant Basmati Saffron Rice', 'Served with Mirchi Ka Salan', 'Nawabi Spiced Marinated Meat'],
    'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600'
  ),
  (
    'Gaming',
    'BGMI Pochinki',
    array['Hot-Drop Red Roof Chaos', 'Church Sniper Vantage Point', 'Blue Zone Vehicle Sprint', 'Flare Gun Airdrop Crate'],
    'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=600'
  ),
  (
    'Gaming',
    'Among Us',
    array['Red Spaceship Astronaut Vent', 'Emergency Table Meeting', 'Sabotaged Oxygen Reactor', 'Electrical Room Task Trap'],
    null
  ),
  (
    'Memes',
    'Hera Pheri Baburao',
    array['Star Garage Telephone Ring', 'Dhoti Dhoti Khopdi Tod Saale', 'Devi Prasad Ghar Pe Hai', 'Raju Double Money Scheme'],
    null
  ),
  (
    'Memes',
    'Moye Moye',
    array['Melodramatic Serbian Chorus Trend', 'Tragic Comic Sudden Twist', 'Hands Behind Back Pose', 'Reels Viral Background Track'],
    null
  )
on conflict do nothing;

