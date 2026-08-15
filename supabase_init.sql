-- =============================================
-- 学习打卡 · Supabase 表重建脚本（2026-08-15）
-- 为什么重建：旧表是 7 月"每行一个 task"结构，带 mode 等 NOT NULL 旧列，
--   新版代码写 {date, data, updated_at} 会违反 NOT NULL 约束报 400。
-- 旧数据说明：旧表 7 月的几行 data 全是 {}（空壳，真实打卡内容早已不在云端），
--   重建无任何数据损失，放心执行。
-- 用法：Supabase Dashboard → SQL Editor → 全选粘贴 → Run（看到 Success 即可）
-- =============================================

-- 1. 删旧表（旧结构不兼容，直接重建）
drop table if exists public.daily_tasks;

-- 2. 建新表：date 主键 + data(jsonb) + updated_at
create table public.daily_tasks (
  date text primary key,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- 3. 开启行级安全
alter table public.daily_tasks enable row level security;

-- 4. RLS 策略（publishable/anon key 可读写，date 必须是 8 位数字）
create policy "daily_tasks_read_all"
  on public.daily_tasks for select using (true);

create policy "daily_tasks_insert_all"
  on public.daily_tasks for insert
  with check (date ~ '^[0-9]{8}$');

create policy "daily_tasks_update_all"
  on public.daily_tasks for update
  using (date ~ '^[0-9]{8}$')
  with check (date ~ '^[0-9]{8}$');

-- 5. 验证（应看到 date/data/updated_at 三列）
-- select column_name, data_type from information_schema.columns where table_name='daily_tasks' order by ordinal_position;
