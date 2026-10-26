-- ============================================================================
-- GET THE GADDAR — SUPABASE REALTIME SCHEMA & MULTI-PHONE BARRIER RPCs (v2.0)
-- ============================================================================

create extension if not exists "pgcrypto";

-- 1. ROOMS TABLE (6-Digit Code, Custom Settings, Active Round & Secret Word)
create table if not exists public.rooms (
  id uuid primary key default gen_random_uuid(),
  room_code varchar(6) unique not null,
  host_player_id uuid not null,
  status varchar(24) not null default 'lobby'
    check (status in ('lobby', 'role_reveal', 'discussion', 'voting', 'last_chance', 'round_result', 'game_over')),
  current_round int not null default 1,
  max_rounds int not null default 4,
  impostor_count int not null default 1,
  discussion_timer_sec int not null default 90,
  impostor_gets_hint boolean not null default true,
  clue_rule varchar(24) not null default 'one_word'
    check (clue_rule in ('one_word', 'two_words', 'no_gestures', 'rhyme_only')),
  selected_categories text[] not null default array['Movies','Cricket','Anime','Celebrities','Indian Food','Gaming','Memes','Custom Words'],
  secret_word text,
  secret_hint text,
  secret_category text,
  caught_gaddar_id uuid,
  caught_gaddar_name text,
  last_chance_guess text,
  winner_team varchar(16), -- 'friends' | 'gaddar' | null
  win_reason text,
  phase_started_at timestamptz default now(),
  created_at timestamptz not null default now()
);

-- 2. PLAYERS TABLE (No Account Required — Per-Phone Guest Identity & Barrier State)
create table if not exists public.players (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  device_id text not null,
  nickname varchar(32) not null,
  avatar_index int not null default 0,
  is_host boolean not null default false,
  role varchar(16) not null default 'friend' check (role in ('friend', 'gaddar')),
  is_eliminated boolean not null default false,
  has_ready boolean not null default false,
  has_voted_current_round boolean not null default false,
  secret_score int not null default 0,
  correct_gaddar_votes int not null default 0,
  rounds_survived_as_gaddar int not null default 0,
  joined_at timestamptz not null default now(),
  unique(room_id, device_id)
);

-- 3. CUSTOM WORDS TABLE (Friends Crowdsource Words in Lobby from Separate Phones)
create table if not exists public.custom_words (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  word text not null,
  hint text not null,
  author_player_id uuid references public.players(id) on delete set null,
  author_nickname text,
  created_at timestamptz not null default now()
);

-- 4. ANONYMOUS VOTES TABLE (Voters' Names Hidden in UI; Even Gaddar Votes)
create table if not exists public.votes (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  round_number int not null,
  voter_id uuid not null references public.players(id) on delete cascade,
  suspect_id uuid not null references public.players(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(room_id, round_number, voter_id)
);

-- Enable Supabase Realtime for all 4 tables
alter publication supabase_realtime add table public.rooms;
alter publication supabase_realtime add table public.players;
alter publication supabase_realtime add table public.custom_words;
alter publication supabase_realtime add table public.votes;

-- Row Level Security: Frictionless No-Account Guest Access
alter table public.rooms enable row level security;
alter table public.players enable row level security;
alter table public.custom_words enable row level security;
alter table public.votes enable row level security;

drop policy if exists "Public rooms access" on public.rooms;
create policy "Public rooms access" on public.rooms for all using (true) with check (true);

drop policy if exists "Public players access" on public.players;
create policy "Public players access" on public.players for all using (true) with check (true);

drop policy if exists "Public custom_words access" on public.custom_words;
create policy "Public custom_words access" on public.custom_words for all using (true) with check (true);

drop policy if exists "Public votes access" on public.votes;
create policy "Public votes access" on public.votes for all using (true) with check (true);

-- ============================================================================
-- RPC 1: START MATCH (Assigns Secret Word, Hint & Gaddar Roles Across Phones)
-- ============================================================================
create or replace function public.start_match(
  p_room_id uuid,
  p_secret_word text,
  p_secret_hint text,
  p_secret_category text,
  p_gaddar_ids uuid[]
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
-- RPC 2: CONSENSUS BARRIER — MARK PLAYER READY & ADVANCE ONLY WHEN ALL PRESS IT
-- ============================================================================
create or replace function public.mark_player_ready(
  p_room_id uuid,
  p_player_id uuid,
  p_target_status varchar
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_room record;
  v_total_active int;
  v_ready_count int;
begin
  select * into v_room from public.rooms where id = p_room_id for update;

  update public.players
  set has_ready = true
  where id = p_player_id and room_id = p_room_id;

  select count(*), count(*) filter (where has_ready = true)
  into v_total_active, v_ready_count
  from public.players
  where room_id = p_room_id and is_eliminated = false;

  -- ONLY transition room status when EVERY active player has pressed the button!
  if v_ready_count >= v_total_active and v_total_active > 0 then
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

    return jsonb_build_object(
      'advanced', true,
      'ready_count', v_ready_count,
      'total_active', v_total_active,
      'new_status', p_target_status
    );
  end if;

  return jsonb_build_object(
    'advanced', false,
    'ready_count', v_ready_count,
    'total_active', v_total_active,
    'new_status', v_room.status
  );
end;
$$;

-- ============================================================================
-- RPC 3: RESOLVE ROUND VOTES (Hidden Leaderboard Scoring + Survival Rule)
-- ============================================================================
create or replace function public.resolve_round_votes(
  p_room_id uuid,
  p_round int
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_room record;
  v_top_suspect uuid;
  v_top_suspect_name text;
  v_top_suspect_role text;
  v_top_votes int := 0;
  v_second_votes int := 0;
  v_total_players int := 0;
  v_survival_target int;
begin
  select * into v_room from public.rooms where id = p_room_id for update;

  if v_room.status <> 'voting' then
    return jsonb_build_object('already_resolved', true, 'status', v_room.status);
  end if;

  select count(*) into v_total_players from public.players where room_id = p_room_id;
  v_survival_target := greatest(1, floor(v_total_players / 3.0)::int);

  -- 1. HIDDEN LEADERBOARD BONUS:
  -- Every Friend who voted for ANY true Gaddar this round gets +50 secret points
  update public.players p
  set secret_score = p.secret_score + 50,
      correct_gaddar_votes = p.correct_gaddar_votes + 1
  from public.votes v
  join public.players suspect on suspect.id = v.suspect_id
  where v.room_id = p_room_id
    and v.round_number = p_round
    and v.voter_id = p.id
    and p.role = 'friend'
    and suspect.role = 'gaddar';

  -- 2. Find top voted suspect and check for tie
  select suspect_id, count(*) as c
  into v_top_suspect, v_top_votes
  from public.votes
  where room_id = p_room_id and round_number = p_round
  group by suspect_id
  order by c desc
  limit 1;

  select coalesce(max(c), 0)
  into v_second_votes
  from (
    select suspect_id, count(*) as c
    from public.votes
    where room_id = p_room_id and round_number = p_round and suspect_id <> v_top_suspect
    group by suspect_id
  ) sub;

  update public.players set has_ready = false where room_id = p_room_id;

  -- 3. Check if majority/plurality caught a Gaddar (strictly highest votes, no tie)
  if v_top_suspect is not null and v_top_votes > v_second_votes then
    select nickname, role into v_top_suspect_name, v_top_suspect_role
    from public.players where id = v_top_suspect;

    if v_top_suspect_role = 'gaddar' then
      update public.players
      set secret_score = greatest(0, secret_score - 50),
          is_eliminated = true
      where id = v_top_suspect;

      update public.rooms
      set status = 'last_chance',
          caught_gaddar_id = v_top_suspect,
          caught_gaddar_name = v_top_suspect_name,
          win_reason = v_top_suspect_name || ' was caught by majority vote (-50 pts)! They get 1 Last-Chance guess at the Secret Word!',
          phase_started_at = now()
      where id = p_room_id;

      return jsonb_build_object(
        'outcome', 'gaddar_caught_last_chance',
        'caught_gaddar_id', v_top_suspect,
        'caught_gaddar_name', v_top_suspect_name
      );
    end if;
  end if;

  -- 4. Gaddar survived the round (+40 pts)
  update public.players
  set rounds_survived_as_gaddar = rounds_survived_as_gaddar + 1,
      secret_score = secret_score + 40
  where room_id = p_room_id and role = 'gaddar' and is_eliminated = false;

  if p_round > v_survival_target or p_round >= v_room.max_rounds then
    update public.players
    set secret_score = secret_score + 100
    where room_id = p_room_id and role = 'gaddar' and is_eliminated = false;

    update public.rooms
    set status = 'game_over',
        winner_team = 'gaddar',
        win_reason = 'Gaddar survived ' || p_round || ' rounds (> floor(' || v_total_players || ' players / 3) = ' || v_survival_target || ' rounds)! All roles and the hidden leaderboard are now revealed!',
        phase_started_at = now()
    where id = p_room_id;

    return jsonb_build_object('outcome', 'gaddar_survived_win', 'round', p_round);
  else
    update public.rooms
    set status = 'round_result',
        caught_gaddar_id = null,
        caught_gaddar_name = null,
        win_reason = case
          when v_top_votes = v_second_votes then 'Tie vote! No one was eliminated and the Gaddar survived Round ' || p_round || '.'
          else 'Majority voted for ' || coalesce(v_top_suspect_name, 'an innocent Friend') || ' (Friend)! The real Gaddar survived Round ' || p_round || '.'
        end,
        phase_started_at = now()
    where id = p_room_id;

    return jsonb_build_object('outcome', 'next_round', 'round', p_round);
  end if;
end;
$$;

-- ============================================================================
-- RPC 4: CAST ANONYMOUS VOTE FROM SEPARATE PHONE (Auto-Resolves When All Voted)
-- ============================================================================
create or replace function public.cast_anonymous_vote(
  p_room_id uuid,
  p_round int,
  p_voter_id uuid,
  p_suspect_id uuid
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_active_count int;
  v_votes_cast int;
  v_resolution jsonb;
begin
  insert into public.votes (room_id, round_number, voter_id, suspect_id)
  values (p_room_id, p_round, p_voter_id, p_suspect_id)
  on conflict (room_id, round_number, voter_id)
  do update set suspect_id = excluded.suspect_id;

  update public.players
  set has_voted_current_round = true
  where id = p_voter_id and room_id = p_room_id;

  select count(*) into v_active_count
  from public.players
  where room_id = p_room_id and is_eliminated = false;

  select count(*) into v_votes_cast
  from public.votes
  where room_id = p_room_id and round_number = p_round;

  if v_votes_cast >= v_active_count and v_active_count > 0 then
    v_resolution := public.resolve_round_votes(p_room_id, p_round);
    return jsonb_build_object(
      'all_voted', true,
      'votes_cast', v_votes_cast,
      'active_count', v_active_count,
      'resolution', v_resolution
    );
  end if;

  return jsonb_build_object(
    'all_voted', false,
    'votes_cast', v_votes_cast,
    'active_count', v_active_count
  );
end;
$$;

-- ============================================================================
-- RPC 5: RESOLVE CAUGHT GADDAR'S LAST-CHANCE SECRET WORD GUESS
-- ============================================================================
create or replace function public.resolve_last_chance_guess(
  p_room_id uuid,
  p_gaddar_id uuid,
  p_guess text
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_room record;
  v_norm_guess text;
  v_norm_secret text;
  v_remaining_gaddars int;
begin
  select * into v_room from public.rooms where id = p_room_id for update;

  v_norm_guess := lower(regexp_replace(coalesce(p_guess, ''), '[^a-zA-Z0-9]', '', 'g'));
  v_norm_secret := lower(regexp_replace(coalesce(v_room.secret_word, ''), '[^a-zA-Z0-9]', '', 'g'));

  if v_norm_guess <> '' and v_norm_guess = v_norm_secret then
    update public.players
    set secret_score = secret_score + 150
    where id = p_gaddar_id and room_id = p_room_id;

    update public.rooms
    set status = 'game_over',
        last_chance_guess = p_guess,
        winner_team = 'gaddar',
        win_reason = coalesce(v_room.caught_gaddar_name, 'Gaddar') || ' was caught by majority vote, but correctly guessed the Secret Word ("' || v_room.secret_word || '") in Last Chance (+150 pts) to steal the win!',
        phase_started_at = now()
    where id = p_room_id;

    return jsonb_build_object('correct', true, 'winner_team', 'gaddar');
  else
    select count(*) into v_remaining_gaddars
    from public.players
    where room_id = p_room_id and role = 'gaddar' and is_eliminated = false;

    if v_remaining_gaddars > 0 and v_room.current_round < v_room.max_rounds then
      update public.rooms
      set status = 'round_result',
          last_chance_guess = p_guess,
          win_reason = coalesce(v_room.caught_gaddar_name, 'Gaddar') || ' guessed "' || coalesce(nullif(p_guess, ''), '(no guess)') || '" (Wrong!). They are eliminated, but ' || v_remaining_gaddars || ' Gaddar is still hiding among you!',
          phase_started_at = now()
      where id = p_room_id;

      return jsonb_build_object('correct', false, 'winner_team', null, 'remaining_gaddars', v_remaining_gaddars);
    else
      update public.players
      set secret_score = secret_score + 100
      where room_id = p_room_id and role = 'friend';

      update public.rooms
      set status = 'game_over',
          last_chance_guess = p_guess,
          winner_team = 'friends',
          win_reason = 'Friends caught ' || coalesce(v_room.caught_gaddar_name, 'the Gaddar') || ' and their Last-Chance guess ("' || coalesce(nullif(p_guess, ''), 'Time Expired') || '") missed the Secret Word ("' || v_room.secret_word || '")! Friends win (+100 pts)!',
          phase_started_at = now()
      where id = p_room_id;

      return jsonb_build_object('correct', false, 'winner_team', 'friends');
    end if;
  end if;
end;
$$;
