-- =============================================================================
-- Migration: V001__initial_schema.sql
-- Description: Initial PocketLedger schema — single-user expenses table
-- Applied: ~June 2026 (project start)
-- Author: Bhawuk Arora
-- Notes: Each user can only see their own expenses. RLS is enforced via
--        auth.uid() = user_id. This is the original schema the app launched with.
-- =============================================================================

-- Create expenses table
CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount DOUBLE PRECISION NOT NULL,
    category TEXT NOT NULL,
    place TEXT,
    date TIMESTAMPTZ NOT NULL DEFAULT now(),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

-- RLS Policies: each user is fully isolated
CREATE POLICY "Users can create their own expenses."
ON public.expenses FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own expenses."
ON public.expenses FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own expenses."
ON public.expenses FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own expenses."
ON public.expenses FOR DELETE
USING (auth.uid() = user_id);
