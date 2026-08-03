-- 1. Create Companies Table
CREATE TABLE IF NOT EXISTS public.companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS on Companies
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;

-- 2. Create Company Members Table
CREATE TABLE IF NOT EXISTS public.company_members (
    company_id UUID NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member', -- e.g., 'admin', 'member'
    created_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (company_id, user_id)
);

-- Enable RLS on Company Members
ALTER TABLE public.company_members ENABLE ROW LEVEL SECURITY;

-- 3. Modify Expenses Table
-- Add company_id, nullable at first to allow migration of existing data
ALTER TABLE public.expenses 
ADD COLUMN IF NOT EXISTS company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE;

-- Optional Migration Step: 
-- You may want to run a script to create a "Personal" company for each existing user 
-- and update their existing expenses to have that company_id.
-- After migration, you can enforce NOT NULL:
-- ALTER TABLE public.expenses ALTER COLUMN company_id SET NOT NULL;

-- 4. Update RLS Policies

-- Drop existing expenses policies
DROP POLICY IF EXISTS "Users can create their own expenses." ON public.expenses;
DROP POLICY IF EXISTS "Users can view their own expenses." ON public.expenses;
DROP POLICY IF EXISTS "Users can update their own expenses." ON public.expenses;
DROP POLICY IF EXISTS "Users can delete their own expenses." ON public.expenses;

-- Create Multi-Tenant RLS for Expenses
-- Users can do CRUD if they are a member of the expense's company
CREATE POLICY "Company members can view expenses."
ON public.expenses FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.company_members 
    WHERE company_members.company_id = expenses.company_id 
    AND company_members.user_id = auth.uid()
  )
);

CREATE POLICY "Company members can create expenses."
ON public.expenses FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.company_members 
    WHERE company_members.company_id = expenses.company_id 
    AND company_members.user_id = auth.uid()
  )
);

CREATE POLICY "Company members can update expenses."
ON public.expenses FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.company_members 
    WHERE company_members.company_id = expenses.company_id 
    AND company_members.user_id = auth.uid()
  )
);

CREATE POLICY "Company members can delete expenses."
ON public.expenses FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM public.company_members 
    WHERE company_members.company_id = expenses.company_id 
    AND company_members.user_id = auth.uid()
  )
);

-- Multi-Tenant RLS for Companies
CREATE POLICY "Users can view companies they belong to."
ON public.companies FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.company_members 
    WHERE company_members.company_id = companies.id 
    AND company_members.user_id = auth.uid()
  )
);

-- Multi-Tenant RLS for Company Members
CREATE POLICY "Users can view members of their companies."
ON public.company_members FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.company_members AS cm 
    WHERE cm.company_id = company_members.company_id 
    AND cm.user_id = auth.uid()
  )
);
