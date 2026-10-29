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

-- ============================================================================
-- 5. HOST MIGRATION & CLEAN EXIT RPC
-- ============================================================================
create or replace function public.leave_room(
  p_room_id uuid,
  p_player_id uuid
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_is_host boolean;
  v_next_host_id uuid;
  v_remaining_count int;
begin
  select is_host into v_is_host
  from public.players
  where id = p_player_id and room_id = p_room_id;

  -- Delete leaving player & their votes
  delete from public.players where id = p_player_id and room_id = p_room_id;
  delete from public.votes where voter_id = p_player_id and room_id = p_room_id;

  select count(*) into v_remaining_count
  from public.players
  where room_id = p_room_id;

  if v_remaining_count = 0 then
    delete from public.rooms where id = p_room_id;
    return jsonb_build_object('action', 'room_deleted');
  end if;

  if v_is_host = true then
    select id into v_next_host_id
    from public.players
    where room_id = p_room_id
    order by joined_at asc
    limit 1;

    if v_next_host_id is not null then
      update public.players set is_host = true where id = v_next_host_id;
      update public.rooms set host_player_id = v_next_host_id where id = p_room_id;
      return jsonb_build_object('action', 'host_migrated', 'new_host_id', v_next_host_id);
    end if;
  end if;

  return jsonb_build_object('action', 'player_left', 'remaining', v_remaining_count);
end;
$$;

-- ============================================================================
-- 6. HOST OVERRIDE / FORCE ADVANCE RPCs (ANTI-DEADLOCK FOR AFK PHONES)
-- ============================================================================
create or replace function public.force_advance_phase(
  p_room_id uuid,
  p_target_status varchar
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_room record;
begin
  select * into v_room from public.rooms where id = p_room_id for update;
  if not found then
    return jsonb_build_object('success', false, 'error', 'Room not found');
  end if;

  update public.players
  set has_ready = false,
      has_voted_current_round = case when p_target_status = 'voting' then false else has_voted_current_round end
  where room_id = p_room_id;

  if v_room.status = 'round_result' and p_target_status = 'discussion' then
    update public.rooms
    set status = 'discussion',
        current_round = current_round + 1,
        caught_gaddar_id = null,
        caught_gaddar_name = null,
        phase_started_at = now()
    where id = p_room_id;
  else
    update public.rooms
    set status = p_target_status,
        phase_started_at = now()
    where id = p_room_id;
  end if;

  return jsonb_build_object('success', true, 'status', p_target_status);
end;
$$;

create or replace function public.force_resolve_round_votes(
  p_room_id uuid,
  p_round int
)
returns jsonb
language plpgsql
security definer
as $$
begin
  return public.resolve_round_votes(p_room_id, p_round);
end;
$$;

-- ============================================================================
-- 7. HOST KICK PLAYER RPC (WITH GADDAR SAFEGUARD & AUTO-RESOLVE)
-- ============================================================================
create or replace function public.kick_player(
  p_room_id uuid,
  p_player_id uuid,
  p_host_id uuid
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_is_host boolean;
  v_kicked_role text;
  v_kicked_name text;
  v_room record;
  v_remaining_gaddars int;
  v_remaining_count int;
  v_active_count int;
  v_votes_cast int;
begin
  -- 1. Verify caller is host
  select is_host into v_is_host
  from public.players
  where id = p_host_id and room_id = p_room_id;

  if v_is_host is not true then
    return jsonb_build_object('success', false, 'error', 'Only the room host can kick players.');
  end if;

  -- Cannot kick oneself as host
  if p_player_id = p_host_id then
    return jsonb_build_object('success', false, 'error', 'Host cannot kick themselves.');
  end if;

  select role, nickname into v_kicked_role, v_kicked_name
  from public.players
  where id = p_player_id and room_id = p_room_id;

  if not found then
    return jsonb_build_object('success', false, 'error', 'Player not found in room.');
  end if;

  -- 2. Delete player & their votes
  delete from public.players where id = p_player_id and room_id = p_room_id;
  delete from public.votes where voter_id = p_player_id and room_id = p_room_id;

  select * into v_room from public.rooms where id = p_room_id for update;

  -- 3. If in active match, check if kicked player was the Gaddar!
  if v_room.status <> 'lobby' and v_room.status <> 'game_over' then
    select count(*) into v_remaining_gaddars
    from public.players
    where room_id = p_room_id and role = 'gaddar' and is_eliminated = false;

    -- If no Gaddars remain, Friends win automatically!
    if v_remaining_gaddars = 0 then
      update public.rooms
      set status = 'game_over',
          winner_team = 'friends',
          win_reason = coalesce(v_kicked_name, 'The Gaddar') || ' was removed from the match. All Gaddars are gone — Friends Win!',
          phase_started_at = now()
      where id = p_room_id;

      return jsonb_build_object('success', true, 'action', 'gaddar_kicked_game_over');
    end if;

    -- If in voting phase, check if all remaining active players have voted
    if v_room.status = 'voting' then
      select count(*) into v_active_count
      from public.players
      where room_id = p_room_id and is_eliminated = false;

      select count(*) into v_votes_cast
      from public.votes
      where room_id = p_room_id and round_number = v_room.current_round;

      if v_votes_cast >= v_active_count and v_active_count > 0 then
        perform public.resolve_round_votes(p_room_id, v_room.current_round);
      end if;
    end if;
  end if;

  select count(*) into v_remaining_count from public.players where room_id = p_room_id;
  return jsonb_build_object('success', true, 'action', 'player_kicked', 'kicked_name', v_kicked_name, 'remaining', v_remaining_count);
end;
$$;

grant execute on function public.kick_player_safely(uuid, uuid, uuid) to anon, authenticated, service_role;

-- ============================================================================
-- 5. AUTOMATED STALE ROOM CLEANUP
-- ============================================================================
-- Automatically purges abandoned lobbies (>6h), finished games (>2h),
-- or any lingering rooms older than p_hours_old (default 24h).
-- Cascading foreign keys safely remove attached players, votes, and custom words.
create or replace function public.cleanup_stale_rooms(p_hours_old int default 24)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_deleted_count int := 0;
begin
  delete from public.rooms
  where created_at < (now() - (p_hours_old || ' hours')::interval)
     or (status = 'game_over' and created_at < (now() - interval '2 hours'))
     or (status = 'lobby' and created_at < (now() - interval '6 hours'));

  get diagnostics v_deleted_count = row_count;

  return jsonb_build_object(
    'success', true,
    'deleted_rooms', v_deleted_count,
    'cleaned_at', now()
  );
exception
  when others then
    return jsonb_build_object('success', false, 'error', SQLERRM);
end;
$$;

grant execute on function public.cleanup_stale_rooms(int) to anon, authenticated, service_role;



