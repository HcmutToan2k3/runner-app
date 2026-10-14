-- Runner app: initial schema
-- Apply with: supabase db push   (or paste into the Supabase SQL editor)

create extension if not exists pgcrypto;

-- ---------- tables ----------

create table schools (
  id   uuid primary key default gen_random_uuid(),
  name text not null
);

create type user_role as enum ('teacher', 'student');

create table profiles (
  id           uuid primary key references auth.users on delete cascade,
  name         text not null default '',
  email        text not null default '',
  role         user_role not null default 'student',
  school_id    uuid references schools,
  student_code text
);

create table class_groups (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  teacher_id uuid not null references profiles on delete cascade,
  join_code  text not null unique default upper(substr(md5(random()::text), 1, 6)),
  created_at timestamptz not null default now()
);

create table class_members (
  class_id   uuid references class_groups on delete cascade,
  student_id uuid references profiles on delete cascade,
  joined_at  timestamptz not null default now(),
  primary key (class_id, student_id)
);

create table assignments (
  id             uuid primary key default gen_random_uuid(),
  class_id       uuid not null references class_groups on delete cascade,
  title          text not null,
  target_km      numeric(6,2) not null check (target_km > 0),
  time_limit_sec int,
  due_at         timestamptz
);

create type run_status as enum ('synced', 'approved', 'flagged');

create table runs (
  id                  uuid primary key,             -- generated on the phone
  student_id          uuid not null references profiles on delete cascade,
  assignment_id       uuid references assignments on delete set null,
  started_at          timestamptz not null,
  duration_sec        int not null check (duration_sec >= 0),
  distance_km         numeric(7,3) not null check (distance_km >= 0),
  avg_pace_sec_per_km numeric(8,2),
  status              run_status not null default 'synced',
  created_at          timestamptz not null default now()
);
create index on runs (assignment_id);
create index on runs (student_id, started_at desc);

create table gps_points (
  run_id     uuid not null references runs on delete cascade,
  seq        int  not null,
  lat        double precision not null,
  lng        double precision not null,
  accuracy_m real not null,
  speed_mps  real not null,
  t          timestamptz not null,
  primary key (run_id, seq)
);

create table run_validations (
  run_id      uuid primary key references runs on delete cascade,
  speed_ok    boolean not null,
  gaps_ok     boolean not null,
  flag_reason text,
  checked_at  timestamptz not null default now()
);

-- ---------- helpers ----------

-- New sign-ups get a profile row automatically (role can be set in user metadata).
create function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, email, name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', ''),
    coalesce((new.raw_user_meta_data->>'role')::user_role, 'student')
  );
  return new;
end $$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function handle_new_user();

create function is_teacher_of_class(c uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from class_groups where id = c and teacher_id = auth.uid());
$$;

create function is_teacher_of_student(s uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from class_members m join class_groups g on g.id = m.class_id
    where m.student_id = s and g.teacher_id = auth.uid()
  );
$$;

-- Students join a class with the teacher's 6-character code.
create function join_class(code text) returns uuid
language plpgsql security definer set search_path = public as $$
declare cid uuid;
begin
  select id into cid from class_groups where join_code = upper(code);
  if cid is null then raise exception 'Invalid class code'; end if;
  insert into class_members (class_id, student_id) values (cid, auth.uid())
    on conflict do nothing;
  return cid;
end $$;

-- Best run per student for an assignment (fastest that meets the target distance).
create function assignment_leaderboard(p_assignment_id uuid)
returns table (student_id uuid, student_name text, distance_km numeric, duration_sec int, status run_status)
language sql stable set search_path = public as $$
  select * from (
    select distinct on (r.student_id)
           r.student_id, p.name, r.distance_km, r.duration_sec, r.status
    from runs r
    join profiles p on p.id = r.student_id
    join assignments a on a.id = r.assignment_id
    where r.assignment_id = p_assignment_id
      and r.distance_km >= a.target_km
    order by r.student_id, r.duration_sec asc
  ) best
  order by best.duration_sec asc
$$;

-- ---------- row level security ----------

alter table schools         enable row level security;
alter table profiles        enable row level security;
alter table class_groups    enable row level security;
alter table class_members   enable row level security;
alter table assignments     enable row level security;
alter table runs            enable row level security;
alter table gps_points      enable row level security;
alter table run_validations enable row level security;

create policy "read schools" on schools for select to authenticated using (true);

create policy "own profile" on profiles for select using (id = auth.uid() or is_teacher_of_student(id));
create policy "update own profile" on profiles for update using (id = auth.uid())
  with check (id = auth.uid() and role = (select role from profiles where id = auth.uid()));

create policy "teacher manages classes" on class_groups for all
  using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());
create policy "student sees joined classes" on class_groups for select
  using (exists (select 1 from class_members m where m.class_id = class_groups.id and m.student_id = auth.uid()));

create policy "members visible" on class_members for select
  using (student_id = auth.uid() or is_teacher_of_class(class_id));
create policy "teacher removes member" on class_members for delete using (is_teacher_of_class(class_id));

create policy "teacher manages assignments" on assignments for all
  using (is_teacher_of_class(class_id)) with check (is_teacher_of_class(class_id));
create policy "student sees assignments" on assignments for select
  using (exists (select 1 from class_members m where m.class_id = assignments.class_id and m.student_id = auth.uid()));

create policy "student inserts own runs" on runs for insert with check (student_id = auth.uid());
create policy "read runs" on runs for select using (student_id = auth.uid() or is_teacher_of_student(student_id));
create policy "teacher reviews runs" on runs for update using (is_teacher_of_student(student_id));

create policy "student inserts own points" on gps_points for insert
  with check (exists (select 1 from runs r where r.id = run_id and r.student_id = auth.uid()));
create policy "read points" on gps_points for select
  using (exists (select 1 from runs r where r.id = run_id
                 and (r.student_id = auth.uid() or is_teacher_of_student(r.student_id))));

create policy "read validations" on run_validations for select
  using (exists (select 1 from runs r where r.id = run_id
                 and (r.student_id = auth.uid() or is_teacher_of_student(r.student_id))));
-- run_validations is written only by the validate-run edge function (service role).
