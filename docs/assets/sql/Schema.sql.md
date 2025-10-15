```sql
-- =========================
-- Profiles
-- =========================
CREATE TABLE public.profiles (
  id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id)
);

create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, username)
  values (new.id, new.raw_user_meta_data ->> 'username');
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- =========================
-- Levels
-- =========================
CREATE TABLE public.levels (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  data jsonb
);

-- =========================
-- Player Level Scores
-- (raw values per attempt)
-- =========================
CREATE TABLE public.player_level_scores (
  id UUID NOT NULL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  level_id UUID NOT NULL REFERENCES public.levels(id) ON DELETE CASCADE,
  speed_seconds FLOAT,         -- End Time - Start Time
  accuracy_score INTEGER,      -- Correct Lines - Error Count
  normalized_speed FLOAT,      -- 0-100
  normalized_accuracy FLOAT,   -- 0-100
  data jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =========================
-- Best Level Scores
-- (keeps each player's best scores per level)
-- =========================
CREATE TABLE public.player_best_level_scores (
  id UUID NOT NULL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  level_id UUID NOT NULL REFERENCES public.levels(id) ON DELETE CASCADE,
  best_speed_seconds FLOAT,
  best_accuracy_score INTEGER,
  best_normalized_speed FLOAT,
  best_normalized_accuracy FLOAT,
  last_updated TIMESTAMPTZ DEFAULT now()
);

-- =========================
-- Mastery / Proficiency
-- (global per-player performance)
-- =========================
CREATE TABLE public.player_mastery (
  id UUID NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  proficiency FLOAT,          -- average of normalized scores across levels
  last_updated TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (id)
);
```
