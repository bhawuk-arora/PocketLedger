# PocketLedger — Database Migration Strategy

## Overview
We use a **numbered sequential migration** approach. Every change to the Supabase schema is tracked as a separate, versioned SQL file inside `docs/migrations/`. This gives us a full audit trail of every schema change ever made — who added what, and why.

## Folder Structure

```
docs/
├── migrations/
│   ├── README.md                          ← This file
│   ├── V001__initial_schema.sql           ← First ever schema
│   ├── V002__multi_tenant_workspaces.sql  ← Company workspaces + RLS
│   └── ...                               ← Future migrations
└── architecture/
    └── schema_diagram.md                  ← ERD and notes
```

## Naming Convention
```
V{number}__{short_description}.sql
```
- Version number is zero-padded to 3 digits
- Double underscore `__` separates version from description
- Description uses snake_case

## Rules (Must Follow)
1. **Never edit an already-applied migration.** If something is wrong, create a new migration to fix it.
2. **Migrations are append-only.** Each file is a one-time change, applied in order.
3. **Every migration file must include a header comment** explaining what it does and why.
4. **Test in Supabase SQL Editor** before committing.

## How to Apply
1. Open Supabase Dashboard → SQL Editor
2. Paste and run the migration files **in order** (V001, then V002, etc.)
3. After running, commit the file to Git and push

## Migration History

| Version | Description                        | Applied | Notes                                   |
|---------|------------------------------------|---------|------------------------------------------|
| V001    | Initial `expenses` table + RLS     | ✅ Yes  | Single-user, user_id isolation           |
| V002    | Multi-tenant workspaces + RLS      | ⬜ No   | Adds `companies`, `company_members` tables |
