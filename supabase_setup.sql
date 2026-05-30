-- ============================================================
-- SUPABASE — Script de criação da tabela
--
-- Execute este script no Supabase:
--   1. Acesse seu projeto em https://supabase.com
--   2. Vá em "SQL Editor" no menu lateral
--   3. Cole este código e clique em "Run"
-- ============================================================

-- Cria a tabela que armazena os ciclos de cada usuária
CREATE TABLE IF NOT EXISTS cycle_entries (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,  -- identificador único
  user_id       UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL, -- dono do registro
  start_date    DATE NOT NULL,           -- data de início da menstruação
  end_date      DATE,                    -- data de término (pode ser nulo)
  cycle_length  INTEGER,                 -- duração do ciclo em dias
  period_length INTEGER,                 -- duração do período em dias
  mood          TEXT,                    -- humor (Feliz, Triste, etc.)
  symptoms      TEXT[] DEFAULT '{}',     -- lista de sintomas (array de texto)
  notes         TEXT,                    -- anotações livres
  created_at    TIMESTAMPTZ DEFAULT NOW() -- data de criação do registro
);

-- ── Segurança: Row Level Security (RLS) ────────────────────
-- Garante que cada usuária só veja e altere os SEUS próprios dados.
-- Sem isso, qualquer usuário autenticado poderia ver dados de outros.

-- Ativa a segurança por linha na tabela
ALTER TABLE cycle_entries ENABLE ROW LEVEL SECURITY;

-- Política de SELECT: só vê os próprios registros
CREATE POLICY "Usuária vê apenas seus registros"
  ON cycle_entries FOR SELECT
  USING (auth.uid() = user_id);

-- Política de INSERT: só insere com o próprio user_id
CREATE POLICY "Usuária cria seus próprios registros"
  ON cycle_entries FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Política de UPDATE: só edita os próprios registros
CREATE POLICY "Usuária edita seus próprios registros"
  ON cycle_entries FOR UPDATE
  USING (auth.uid() = user_id);

-- Política de DELETE: só exclui os próprios registros
CREATE POLICY "Usuária exclui seus próprios registros"
  ON cycle_entries FOR DELETE
  USING (auth.uid() = user_id);
