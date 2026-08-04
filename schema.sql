-- ============================================================
-- Shelter Maintenance / Inventory / Vacancy schema for Supabase
-- Run this entire file once in: Supabase Dashboard > SQL Editor > New query
-- ============================================================

-- Needed for gen_random_uuid()
create extension if not exists "pgcrypto";

-- ---------- Profiles (display name for each staff login) ----------
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  created_at timestamptz default now()
);

-- ---------- Rooms ----------
create table if not exists rooms (
  id serial primary key,
  room_number text unique not null,
  notes text
);

-- ---------- Maintenance items ----------
create table if not exists maintenance_items (
  id uuid primary key default gen_random_uuid(),
  room_id int references rooms(id) on delete cascade,
  title text not null,
  category text default 'other',        -- plumbing, electrical, structural, furniture, pest, cleaning, other
  urgency text not null default 'medium', -- low, medium, high, urgent
  status text not null default 'open',    -- open, in_progress, fixed, wont_fix
  description text,
  created_by uuid references profiles(id),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ---------- Maintenance history / audit trail ----------
create table if not exists maintenance_events (
  id uuid primary key default gen_random_uuid(),
  item_id uuid references maintenance_items(id) on delete cascade,
  event_type text not null,   -- created, status_change, comment, photo
  note text,
  old_status text,
  new_status text,
  created_by uuid references profiles(id),
  created_at timestamptz default now()
);

-- ---------- Photos ----------
create table if not exists maintenance_photos (
  id uuid primary key default gen_random_uuid(),
  item_id uuid references maintenance_items(id) on delete cascade,
  event_id uuid references maintenance_events(id) on delete set null,
  storage_path text not null,
  caption text,
  created_by uuid references profiles(id),
  created_at timestamptz default now()
);

-- ---------- Room condition snapshots (baseline "before" photos, not tied to an issue) ----------
create table if not exists room_snapshots (
  id uuid primary key default gen_random_uuid(),
  room_id int references rooms(id) on delete cascade,
  note text,
  created_by uuid references profiles(id),
  created_at timestamptz default now()
);

create table if not exists room_snapshot_photos (
  id uuid primary key default gen_random_uuid(),
  snapshot_id uuid references room_snapshots(id) on delete cascade,
  storage_path text not null,
  created_by uuid references profiles(id),
  created_at timestamptz default now()
);

-- ---------- Inventory (tools + consumables) ----------
create table if not exists inventory_items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null default 'consumable', -- tool, consumable
  quantity numeric not null default 0,
  unit text,                      -- each, box, L, roll, etc
  low_stock_threshold numeric,
  location text,
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ---------- Inventory history ----------
create table if not exists inventory_events (
  id uuid primary key default gen_random_uuid(),
  item_id uuid references inventory_items(id) on delete cascade,
  change_qty numeric not null,     -- positive = restocked/returned, negative = used/checked out
  reason text,                     -- restock, used on room X, checked out, returned, lost/broken
  related_room_id int references rooms(id),
  created_by uuid references profiles(id),
  created_at timestamptz default now()
);

-- ---------- Shopping / "things we need to buy" list ----------
create table if not exists shopping_items (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null default 'other', -- consumable, hardware, fixture, appliance, furniture, other
  quantity numeric not null default 1,
  estimated_cost numeric,               -- rough guess, used to sort hardware-run vs secondhand-first
  notes text,
  room_id int references rooms(id),
  requested_by uuid references profiles(id),
  status text not null default 'needed', -- needed, sourcing, bought, cancelled
  source_type text,                     -- new, secondhand (filled in once bought)
  actual_cost numeric,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ---------- Vacancy (current state, one row per room) ----------
create table if not exists vacancy (
  room_id int primary key references rooms(id) on delete cascade,
  status text not null default 'vacant', -- vacant, occupied, out_of_service
  updated_by uuid references profiles(id),
  updated_at timestamptz default now()
);
-- Optional occupant reference, so condition/damage can be tied to a specific stay.
-- Keep this to the minimum you need (e.g. first name + last initial) — see SETUP.md privacy note.
alter table vacancy add column if not exists current_occupant_name text;

-- ---------- Vacancy history ----------
create table if not exists vacancy_events (
  id uuid primary key default gen_random_uuid(),
  room_id int references rooms(id) on delete cascade,
  old_status text,
  new_status text not null,
  created_by uuid references profiles(id),
  created_at timestamptz default now()
);
alter table vacancy_events add column if not exists occupant_name text;

-- ============================================================
-- Row Level Security
-- Since this is a small internal tool for ~5 trusted staff,
-- policy is simple: any signed-in user can read/write everything.
-- ============================================================

alter table profiles enable row level security;
alter table rooms enable row level security;
alter table maintenance_items enable row level security;
alter table maintenance_events enable row level security;
alter table maintenance_photos enable row level security;
alter table room_snapshots enable row level security;
alter table room_snapshot_photos enable row level security;
alter table inventory_items enable row level security;
alter table inventory_events enable row level security;
alter table shopping_items enable row level security;
alter table vacancy enable row level security;
alter table vacancy_events enable row level security;

drop policy if exists "authenticated read profiles" on profiles;
create policy "authenticated read profiles" on profiles for select using (auth.role() = 'authenticated');
drop policy if exists "user can insert own profile" on profiles;
create policy "user can insert own profile" on profiles for insert with check (auth.uid() = id);
drop policy if exists "user can update own profile" on profiles;
create policy "user can update own profile" on profiles for update using (auth.uid() = id);

drop policy if exists "authenticated all rooms" on rooms;
create policy "authenticated all rooms" on rooms for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
drop policy if exists "authenticated all maintenance_items" on maintenance_items;
create policy "authenticated all maintenance_items" on maintenance_items for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
drop policy if exists "authenticated all maintenance_events" on maintenance_events;
create policy "authenticated all maintenance_events" on maintenance_events for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
drop policy if exists "authenticated all maintenance_photos" on maintenance_photos;
create policy "authenticated all maintenance_photos" on maintenance_photos for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
drop policy if exists "authenticated all room_snapshots" on room_snapshots;
create policy "authenticated all room_snapshots" on room_snapshots for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
drop policy if exists "authenticated all room_snapshot_photos" on room_snapshot_photos;
create policy "authenticated all room_snapshot_photos" on room_snapshot_photos for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
drop policy if exists "authenticated all inventory_items" on inventory_items;
create policy "authenticated all inventory_items" on inventory_items for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
drop policy if exists "authenticated all inventory_events" on inventory_events;
create policy "authenticated all inventory_events" on inventory_events for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
drop policy if exists "authenticated all shopping_items" on shopping_items;
create policy "authenticated all shopping_items" on shopping_items for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
drop policy if exists "authenticated all vacancy" on vacancy;
create policy "authenticated all vacancy" on vacancy for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
drop policy if exists "authenticated all vacancy_events" on vacancy_events;
create policy "authenticated all vacancy_events" on vacancy_events for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- ============================================================
-- Seed rooms 1-34 (edit numbering to match your building, e.g. "101","102"...)
-- ============================================================
insert into rooms (room_number)
select lpad(n::text, 2, '0') from generate_series(1, 34) as n
on conflict (room_number) do nothing;

insert into vacancy (room_id, status)
select id, 'vacant' from rooms
on conflict (room_id) do nothing;

-- ============================================================
-- Storage bucket for photos (private — accessed only via signed URLs)
-- This part can't run in the SQL editor; do it in the dashboard:
-- Storage > Create bucket > name: maintenance-photos > Public: OFF
-- Then run the two policy statements below in the SQL editor.
-- ============================================================

drop policy if exists "authenticated upload photos" on storage.objects;
create policy "authenticated upload photos"
on storage.objects for insert
with check (bucket_id = 'maintenance-photos' and auth.role() = 'authenticated');

drop policy if exists "authenticated read photos" on storage.objects;
create policy "authenticated read photos"
on storage.objects for select
using (bucket_id = 'maintenance-photos' and auth.role() = 'authenticated');

-- ============================================================
-- Live sync: add tables to Supabase's realtime publication so
-- changes one person makes show up on everyone else's screen.
-- Safe to re-run — skips tables already added.
-- ============================================================
do $$
declare t text;
begin
  foreach t in array array[
    'maintenance_items','maintenance_events','maintenance_photos',
    'room_snapshots','room_snapshot_photos',
    'inventory_items','inventory_events',
    'shopping_items',
    'vacancy','vacancy_events'
  ]
  loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;
