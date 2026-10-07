-- ============================================================
-- Nosso Açaí — Ranking "Mais Pedidos"
-- Execute este script no SQL Editor do seu projeto Supabase.
-- ============================================================

-- Tabela que guarda cada combinação de copo e sua contagem interna.
-- A contagem NUNCA é exibida ao cliente — usada só para ordenar o ranking.
create table if not exists public.combo_counts (
  combo_key   text primary key,       -- chave normalizada (tamanho + ingredientes ordenados)
  label       text not null,          -- texto amigável exibido no card do ranking
  size_id     text,
  base        jsonb not null default '[]'::jsonb,
  frutas      jsonb not null default '[]'::jsonb,
  cremes      jsonb not null default '[]'::jsonb,
  acomp       jsonb not null default '[]'::jsonb,
  order_count integer not null default 0,
  updated_at  timestamptz not null default now()
);

-- Habilita Row Level Security. Sem policies de escrita direta —
-- toda escrita passa pela função increment_combo (abaixo), que roda
-- com privilégios de definidor e não expõe segredos ao cliente.
alter table public.combo_counts enable row level security;

-- Qualquer pessoa pode LER o ranking (necessário para o site mostrar
-- "Mais Pedidos" sem exigir login).
drop policy if exists "combo_counts_select_public" on public.combo_counts;
create policy "combo_counts_select_public"
  on public.combo_counts
  for select
  using (true);

-- Função que incrementa (ou cria) a contagem de uma combinação.
-- security definer: executa com as permissões do dono da função,
-- então o cliente (chave anon) não precisa de permissão de INSERT/UPDATE
-- direta na tabela — só pode chamar esta função via RPC.
create or replace function public.increment_combo(
  p_combo_key text,
  p_label     text,
  p_size_id   text,
  p_base      jsonb,
  p_frutas    jsonb,
  p_cremes    jsonb,
  p_acomp     jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.combo_counts (combo_key, label, size_id, base, frutas, cremes, acomp, order_count, updated_at)
  values (p_combo_key, p_label, p_size_id, p_base, p_frutas, p_cremes, p_acomp, 1, now())
  on conflict (combo_key) do update
    set order_count = combo_counts.order_count + 1,
        label       = excluded.label,
        updated_at  = now();
end;
$$;

-- Permite que o cliente (papel "anon", usado pela chave anon pública)
-- chame a função de incremento e leia a tabela.
grant usage on schema public to anon;
grant execute on function public.increment_combo(text, text, text, jsonb, jsonb, jsonb, jsonb) to anon;
grant select on public.combo_counts to anon;

-- ============================================================
-- Fim do script.
-- ============================================================
