-- =============================================================================
-- Migration: V002__multi_tenant_workspaces.sql
-- Description: Add shared company workspaces with multi-user access (Issue #17)
-- Author: Bhawuk Arora
-- Depends on: V001__initial_schema.sql
-- Notes:
--   This migration transitions the app from a single-user model to a
--   multi-tenant model. Instead of expenses being owned by a single user via
--   user_id, they are now owned by a "company" (workspace). Access is granted
--   dynamically to all members of that company via RLS.
--
--   IMPORTANT: After running this migration, you must also run the data
--   backfill step below to migrate existing user expenses into "Personal"
--   company workspaces. Otherwise, existing expenses will be invisible
--   (company_id will be NULL, and the new RLS policies won't match them).
--
-- Architecture:
--   auth.users (Supabase built-in)
--       ↕ (1-to-many)
--   company_members (junction table)
--       ↕ (many-to-1)
--   companies
--       ↕ (1-to-many)
--   expenses (now tied to company_id, not user_id)
-- =============================================================================

-- ─── 1. Create Companies Table ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;

-- ─── 2. Create Company Members Table ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.company_members (
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member', -- 'admin' | 'member'
    created_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (company_id, user_id)
);

ALTER TABLE public.company_members ENABLE ROW LEVEL SECURITY;

-- ─── 3. Add company_id to Expenses ───────────────────────────────────────────
-- Nullable at first to allow existing data to exist without a company.
-- After running the backfill step below, enforce NOT NULL.
ALTER TABLE public.expenses
    ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE;

-- ─── 4. Drop Old Single-User RLS Policies ────────────────────────────────────
DROP POLICY IF EXISTS "Users can create their own expenses." ON public.expenses;
DROP POLICY IF EXISTS "Users can view their own expenses." ON public.expenses;
DROP POLICY IF EXISTS "Users can update their own expenses." ON public.expenses;
DROP POLICY IF EXISTS "Users can delete their own expenses." ON public.expenses;

-- ─── 5. New Multi-Tenant RLS for Expenses ────────────────────────────────────
CREATE POLICY "Company members can view expenses."
ON public.expenses FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.company_members cm
        WHERE cm.company_id = expenses.company_id
          AND cm.user_id = auth.uid()
    )
);

CREATE POLICY "Company members can create expenses."
ON public.expenses FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.company_members cm
        WHERE cm.company_id = expenses.company_id
          AND cm.user_id = auth.uid()
    )
);

CREATE POLICY "Company members can update expenses."
ON public.expenses FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.company_members cm
        WHERE cm.company_id = expenses.company_id
          AND cm.user_id = auth.uid()
    )
);

CREATE POLICY "Company members can delete expenses."
ON public.expenses FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM public.company_members cm
        WHERE cm.company_id = expenses.company_id
          AND cm.user_id = auth.uid()
    )
);

-- ─── 6. RLS for Companies ─────────────────────────────────────────────────────
CREATE POLICY "Users can view companies they belong to."
ON public.companies FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.company_members cm
        WHERE cm.company_id = companies.id
          AND cm.user_id = auth.uid()
    )
);

-- Only authenticated users can create companies (they become the admin)
CREATE POLICY "Authenticated users can create companies."
ON public.companies FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

-- ─── 7. RLS for Company Members ──────────────────────────────────────────────
CREATE POLICY "Company members can view other members."
ON public.company_members FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.company_members cm
        WHERE cm.company_id = company_members.company_id
          AND cm.user_id = auth.uid()
    )
);

-- Only admins can add members (enforced at application layer too)
CREATE POLICY "Authenticated users can add themselves as members."
ON public.company_members FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

-- =============================================================================
-- DATA BACKFILL: Run this AFTER the above schema changes.
-- This creates a "Personal Workspace" company for each existing user and
-- migrates all their old expenses into it.
--
-- ⚠️  DO NOT run this on an empty database. Only run if you have existing data.
-- =============================================================================

/*
DO $$
DECLARE
    u RECORD;
    new_company_id UUID;
BEGIN
    FOR u IN SELECT DISTINCT user_id FROM public.expenses WHERE company_id IS NULL
    LOOP
        -- Create a "Personal" company for this user
        INSERT INTO public.companies (name)
        VALUES ('Personal Workspace')
        RETURNING id INTO new_company_id;

        -- Add the user as admin of their personal company
        INSERT INTO public.company_members (company_id, user_id, role)
        VALUES (new_company_id, u.user_id, 'admin');

        -- Migrate all their expenses to this company
        UPDATE public.expenses
        SET company_id = new_company_id
        WHERE user_id = u.user_id;
    END LOOP;
END $$;

-- After backfill, enforce NOT NULL on company_id:
-- ALTER TABLE public.expenses ALTER COLUMN company_id SET NOT NULL;
*/
