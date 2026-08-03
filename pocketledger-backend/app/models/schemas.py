from pydantic import BaseModel
from typing import Optional, Dict


# ─── Expense Schemas ──────────────────────────────────────────────────────────

class ExpenseCreate(BaseModel):
    amount: float
    category: str
    place: Optional[str] = None
    notes: Optional[str] = None
    date: str
    company_id: str


class ExpenseUpdate(BaseModel):
    amount: Optional[float] = None
    category: Optional[str] = None
    place: Optional[str] = None
    notes: Optional[str] = None
    date: Optional[str] = None


# ─── Report Schemas ───────────────────────────────────────────────────────────

class EmailRequest(BaseModel):
    to_email: str
    month: int
    year: int
    total_spend: float
    previous_month_spend: float
    categories: Dict[str, float]


# ─── Company / Workspace Schemas ──────────────────────────────────────────────

class CompanyCreate(BaseModel):
    name: str


class CompanyMemberAdd(BaseModel):
    user_id: str
    role: str = "member"
