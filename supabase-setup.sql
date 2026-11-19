-- Process Flow Challenge: study database setup (run once in the Supabase SQL editor)
-- Every save from the game is a new row. Browsers may only INSERT; nobody can
-- read, update or delete through the public API. You read results in the
-- Supabase dashboard (Table Editor), which bypasses these rules for the owner.

create table if not exists public.session_saves (
  id                  uuid primary key default gen_random_uuid(),
  created_at          timestamptz not null default now(),
  session_id          uuid not null,
  save_reason         text not null check (char_length(save_reason) <= 40),
  participant         text not null check (char_length(participant) between 1 and 40),
  condition           text not null check (condition in ('coach', 'no-coach')),
  game_version        text check (char_length(game_version) <= 20),
  phase               text check (char_length(phase) <= 20),
  ended_by            text check (char_length(ended_by) <= 20),
  coach_requests      int,
  build_start_s       int,
  first_request_s     int,
  draft_total         int,
  final_total         int,
  baseline_confidence int,
  final_confidence    int,
  client_saved_at     timestamptz,
  payload             jsonb not null check (pg_column_size(payload) < 3000000)
);

create index if not exists session_saves_session_idx on public.session_saves (session_id, created_at desc);

-- Security: insert-only for the game's publishable key
alter table public.session_saves enable row level security;
revoke all on public.session_saves from anon, authenticated;
grant insert on public.session_saves to anon;
drop policy if exists "game can insert sessions" on public.session_saves;
create policy "game can insert sessions" on public.session_saves
  for insert to anon with check (true);

-- One readable row per player: their latest save
create or replace view public.session_summary with (security_invoker = true) as
select distinct on (session_id)
  participant,
  condition,
  created_at                                   as last_saved_at,
  save_reason                                  as last_save,
  ended_by,
  coach_requests,
  round(first_request_s / 60.0, 1)             as first_request_min_into_build,
  draft_total,
  final_total,
  baseline_confidence,
  final_confidence,
  payload->'reflection'->'r1'->>'a'            as reflection_1,
  payload->'reflection'->'r2'->>'a'            as reflection_2,
  payload->'reflection'->'r3'->>'a'            as reflection_3,
  payload->'reflection'->'r4'->>'a'            as reflection_4,
  payload->'reflection'->'r5'->>'a'            as reflection_5,
  payload->'reflection'->'r6'->>'a'            as reflection_6,
  payload->'debrief'                           as debrief_answers,
  payload->'assessment'->'scores'              as final_scores,
  session_id,
  payload
from public.session_saves
order by session_id, created_at desc;

-- One row per AI Friend feedback event: did the player act on it?
create or replace view public.feedback_uptake with (security_invoker = true) as
select
  s.participant,
  s.condition,
  u->>'kind'                                                        as request,
  round(((u->>'t')::numeric / 1000 - coalesce(b.build_start_s, 0)) / 60.0, 1) as min_into_build,
  u->'criteria'                                                     as criteria,
  (u->>'changedWithin3min')::boolean                                as revised_within_3_min,
  (u->>'editsWithin3min')::int                                      as edits_within_3_min,
  (u->>'relatedEdit')::boolean                                      as edit_matched_feedback,
  u->>'response'                                                    as button_response,
  u->'scoreAtRequest'                                               as score_at_request,
  u->'scoreNextSnapshot'                                            as score_after,
  s.session_id
from public.session_summary s
join lateral (select build_start_s from public.session_saves x where x.session_id = s.session_id and x.build_start_s is not null limit 1) b on true
cross join lateral jsonb_array_elements(coalesce(s.payload->'uptake', '[]'::jsonb)) u;

revoke all on public.session_summary from anon, authenticated;
revoke all on public.feedback_uptake from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Results dashboard (/results): returns all sessions ONLY with the correct
-- facilitator passcode. The passcode is stored as a bcrypt hash in a schema
-- the public API cannot see.
-- ---------------------------------------------------------------------------
create schema if not exists app_private;
revoke all on schema app_private from public, anon, authenticated;
create table if not exists app_private.settings (key text primary key, value text not null);

create or replace function public.get_results(passcode text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions, app_private
as $$
declare h text;
begin
  select value into h from app_private.settings where key = 'results_passcode_hash';
  if h is null or crypt('TYPE-YOUR-PASSCODE-HERE', h) = h then
    raise exception 'No results passcode has been set yet' using errcode = '28000';
  end if;
  if passcode is null or length(passcode) < 6 or crypt(passcode, h) <> h then
    perform pg_sleep(1.5);
    raise exception 'Incorrect passcode' using errcode = '28P01';
  end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'session_id', s.session_id, 'participant', s.participant, 'condition', s.condition,
      'last_saved_at', s.last_saved_at, 'last_save', s.last_save, 'ended_by', s.ended_by,
      'coach_requests', s.coach_requests, 'first_request_min', s.first_request_min_into_build,
      'draft_total', s.draft_total, 'final_total', s.final_total,
      'baseline_confidence', s.baseline_confidence, 'final_confidence', s.final_confidence,
      'scores', s.payload->'assessment'->'scores', 'reflection', s.payload->'reflection',
      'debrief', s.payload->'debrief', 'flow', s.payload->'finalFlow', 'uptake', s.payload->'uptake',
      'cp5', s.payload->'cp5Cycles', 'baseline', s.payload->'baseline', 'minutes', s.payload->'meta'->'minutes',
      'coach_messages', s.payload->'coachMessages',
      'events', (select coalesce(jsonb_agg(e), '[]'::jsonb)
                 from jsonb_array_elements(coalesce(s.payload->'events', '[]'::jsonb)) e
                 where e->>'type' in ('phase', 'coach_request', 'feedback_response'))
    ) order by s.last_saved_at desc)
    from public.session_summary s), '[]'::jsonb);
end;
$$;
revoke all on function public.get_results(text) from public, anon, authenticated;
grant execute on function public.get_results(text) to anon;

-- Set or change the dashboard passcode (at least 6 characters). Edit the text
-- between the quotes, then run ONLY this statement:
-- insert into app_private.settings (key, value)
-- values ('results_passcode_hash', extensions.crypt('TYPE-YOUR-PASSCODE-HERE', extensions.gen_salt('bf')))
-- on conflict (key) do update set value = excluded.value;
