# PocketLedger — Schema Architecture

## Entity Relationship Diagram

```
auth.users (Supabase)
     │
     │ 1-to-many (via user_id)
     ▼
company_members ─────────────── companies
     │                               │
     │ many-to-1 (via company_id)    │ 1-to-many
     └──────────────────────────────▶ expenses
```

## Table Descriptions

### `auth.users`
- **Managed by Supabase Auth** — do not create manually.
- `id`: UUID, primary key, referenced everywhere as `user_id`.

### `expenses` (core table)
| Column | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `user_id` | UUID | Who created this expense |
| `company_id` | UUID | Which workspace this belongs to (added in V002) |
| `amount` | DOUBLE PRECISION | Expense amount |
| `category` | TEXT | e.g. Food, Travel, Commute |
| `place` | TEXT | Where it happened |
| `date` | TIMESTAMPTZ | Date of expense |
| `notes` | TEXT | Optional notes |
| `created_at` | TIMESTAMPTZ | Auto-set |

### `companies` (added V002)
| Column | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `name` | TEXT | Workspace name, e.g. "Personal", "Bhawuk's Startup" |
| `created_at` | TIMESTAMPTZ | Auto-set |

### `company_members` (added V002)
| Column | Type | Notes |
|---|---|---|
| `company_id` | UUID | FK → companies |
| `user_id` | UUID | FK → auth.users |
| `role` | TEXT | `admin` or `member` |
| `created_at` | TIMESTAMPTZ | Auto-set |

## RLS Summary

| Table | Policy | Access Logic |
|---|---|---|
| `expenses` | SELECT/INSERT/UPDATE/DELETE | User must be a member of the expense's `company_id` |
| `companies` | SELECT | User must be a member of the company |
| `companies` | INSERT | Any authenticated user can create a company |
| `company_members` | SELECT | Must be a member of the same company |
| `company_members` | INSERT | Any authenticated user (they join a company) |
