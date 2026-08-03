from fastapi import FastAPI, Depends, HTTPException, Header, Request
from pydantic import BaseModel
import os
import httpx
from typing import Optional, List, Dict, Any
from dotenv import load_dotenv
import calendar
from datetime import datetime
import json

load_dotenv()

app = FastAPI(title="PocketLedger Backend")

SUPABASE_URL = os.getenv("SUPABASE_URL", "https://your-supabase-url.supabase.co")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY", "your-anon-key")
RESEND_API_KEY = os.getenv("RESEND_API_KEY", "your-resend-key")

async def get_auth_token(authorization: str = Header(...)):
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authorization header")
    return authorization

class ExpenseCreate(BaseModel):
    user_id: str
    amount: float
    category: str
    place: Optional[str] = None
    notes: Optional[str] = None
    date: str

class ExpenseUpdate(BaseModel):
    amount: Optional[float] = None
    category: Optional[str] = None
    place: Optional[str] = None
    notes: Optional[str] = None
    date: Optional[str] = None

@app.get("/api/transactions")
async def get_transactions(limit: int = 30, offset: int = 0, month: Optional[int] = None, year: Optional[int] = None, token: str = Depends(get_auth_token)):
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": token,
        "Range-Unit": "items",
        "Range": f"{offset}-{offset+limit-1}"
    }
    
    params: Dict[str, Any] = {
        "order": "date.desc,created_at.desc"
    }
    
    if month and year:
        _, last_day = calendar.monthrange(year, month)
        start_date = f"{year}-{month:02d}-01T00:00:00Z"
        end_date = f"{year}-{month:02d}-{last_day:02d}T23:59:59Z"
        
        # PostgREST syntax for AND conditions on the same column is currently best handled by passing them as a list if supported, 
        # or we can use the `and` operator.
        # e.g., and=(date.gte.2023-01-01,date.lte.2023-01-31)
        params["and"] = f"(date.gte.{start_date},date.lte.{end_date})"

    async with httpx.AsyncClient() as client:
        url = f"{SUPABASE_URL}/rest/v1/expenses"
        response = await client.get(url, headers=headers, params=params)
        
        if response.status_code >= 400:
            raise HTTPException(status_code=response.status_code, detail=response.text)
        return response.json()

@app.post("/api/transactions")
async def create_transaction(expense: ExpenseCreate, token: str = Depends(get_auth_token)):
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": token,
        "Prefer": "return=representation",
        "Content-Type": "application/json"
    }
    async with httpx.AsyncClient() as client:
        url = f"{SUPABASE_URL}/rest/v1/expenses"
        response = await client.post(url, headers=headers, json=expense.dict(exclude_none=True))
        if response.status_code >= 400:
            raise HTTPException(status_code=response.status_code, detail=response.text)
        return response.json()[0]

@app.put("/api/transactions/{expense_id}")
async def update_transaction(expense_id: str, expense: ExpenseUpdate, token: str = Depends(get_auth_token)):
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": token,
        "Prefer": "return=representation",
        "Content-Type": "application/json"
    }
    async with httpx.AsyncClient() as client:
        url = f"{SUPABASE_URL}/rest/v1/expenses?id=eq.{expense_id}"
        response = await client.patch(url, headers=headers, json=expense.dict(exclude_none=True))
        if response.status_code >= 400:
            raise HTTPException(status_code=response.status_code, detail=response.text)
        return response.json()[0]

@app.delete("/api/transactions/{expense_id}")
async def delete_transaction(expense_id: str, token: str = Depends(get_auth_token)):
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": token,
    }
    async with httpx.AsyncClient() as client:
        url = f"{SUPABASE_URL}/rest/v1/expenses?id=eq.{expense_id}"
        response = await client.delete(url, headers=headers)
        if response.status_code >= 400:
            raise HTTPException(status_code=response.status_code, detail=response.text)
        return {"status": "deleted"}

@app.get("/api/reports/monthly")
async def get_monthly_report(month: int, year: int, token: str = Depends(get_auth_token)):
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": token,
    }
    
    _, last_day = calendar.monthrange(year, month)
    start_date = f"{year}-{month:02d}-01T00:00:00Z"
    end_date = f"{year}-{month:02d}-{last_day:02d}T23:59:59Z"

    # Previous month logic
    if month == 1:
        prev_month = 12
        prev_year = year - 1
    else:
        prev_month = month - 1
        prev_year = year
        
    _, prev_last_day = calendar.monthrange(prev_year, prev_month)
    prev_start_date = f"{prev_year}-{prev_month:02d}-01T00:00:00Z"
    prev_end_date = f"{prev_year}-{prev_month:02d}-{prev_last_day:02d}T23:59:59Z"

    async with httpx.AsyncClient() as client:
        url = f"{SUPABASE_URL}/rest/v1/expenses"
        # Get current month data
        params_current = {"and": f"(date.gte.{start_date},date.lte.{end_date})", "select": "amount,category"}
        res_current = await client.get(url, headers=headers, params=params_current)
        
        # Get previous month data
        params_prev = {"and": f"(date.gte.{prev_start_date},date.lte.{prev_end_date})", "select": "amount,category"}
        res_prev = await client.get(url, headers=headers, params=params_prev)

        if res_current.status_code >= 400 or res_prev.status_code >= 400:
            raise HTTPException(status_code=500, detail="Failed to fetch aggregation data")

        data_current = res_current.json()
        data_prev = res_prev.json()

        total_current = sum(item["amount"] for item in data_current)
        total_prev = sum(item["amount"] for item in data_prev)
        
        categories = {}
        for item in data_current:
            c = item["category"]
            categories[c] = categories.get(c, 0) + item["amount"]

        # Sort categories by spend desc
        sorted_categories = dict(sorted(categories.items(), key=lambda x: x[1], reverse=True))

        return {
            "month": month,
            "year": year,
            "total_spend": total_current,
            "previous_month_spend": total_prev,
            "categories": sorted_categories,
        }

class EmailRequest(BaseModel):
    to_email: str
    month: int
    year: int
    total_spend: float
    previous_month_spend: float
    categories: Dict[str, float]

@app.post("/api/reports/email")
async def send_report_email(req: EmailRequest, token: str = Depends(get_auth_token)):
    # Very basic resend API call
    if not RESEND_API_KEY or RESEND_API_KEY == "your-resend-key":
        raise HTTPException(status_code=500, detail="RESEND_API_KEY is not configured on the server")
        
    diff = req.total_spend - req.previous_month_spend
    trend_text = f"Up by ₹{diff}" if diff > 0 else f"Down by ₹{abs(diff)}"
    
    html = f"""
    <h2>PocketLedger Monthly Damage Report ({req.month}/{req.year})</h2>
    <p>Total Spend: ₹{req.total_spend}</p>
    <p>Compared to last month: {trend_text}</p>
    <h3>Category Breakdown:</h3>
    <ul>
    """
    for c, amt in req.categories.items():
        html += f"<li>{c}: ₹{amt}</li>"
    html += "</ul>"
    
    headers = {
        "Authorization": f"Bearer {RESEND_API_KEY}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "from": "PocketLedger <onboarding@resend.dev>",
        "to": [req.to_email],
        "subject": f"🦁 Monthly Damage Report: ₹{req.total_spend}",
        "html": html
    }
    
    async with httpx.AsyncClient() as client:
        res = await client.post("https://api.resend.com/emails", headers=headers, json=payload)
        if res.status_code >= 400:
            raise HTTPException(status_code=res.status_code, detail=res.text)
            
        return res.json()
