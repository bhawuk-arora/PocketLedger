from fastapi import APIRouter, Depends, HTTPException, Header
import httpx
import resend
from app.core.config import settings
from app.core.security import get_auth_token, get_company_id
from app.models.schemas import EmailRequest
from collections import defaultdict
import datetime

router = APIRouter()

resend.api_key = settings.RESEND_API_KEY

async def get_supabase_client(token: str = Depends(get_auth_token)):
    headers = {
        "apikey": settings.SUPABASE_ANON_KEY,
        "Authorization": token,
        "Prefer": "return=representation",
        "Content-Type": "application/json"
    }
    return httpx.AsyncClient(headers=headers, base_url=f"{settings.SUPABASE_URL}/rest/v1")

@router.get("/monthly")
async def get_monthly_report(
    month: int,
    year: int,
    client: httpx.AsyncClient = Depends(get_supabase_client),
    company_id: str | None = Depends(get_company_id)
):
    if not company_id:
        raise HTTPException(status_code=400, detail="X-Company-ID header is required")

    # Current month dates
    start_date = f"{year}-{month:02d}-01T00:00:00Z"
    end_month = month + 1 if month < 12 else 1
    end_year = year if month < 12 else year + 1
    end_date = f"{end_year}-{end_month:02d}-01T00:00:00Z"
    
    # Previous month dates
    prev_month = month - 1 if month > 1 else 12
    prev_year = year if month > 1 else year - 1
    prev_start_date = f"{prev_year}-{prev_month:02d}-01T00:00:00Z"
    prev_end_date = start_date

    # Fetch current month expenses
    curr_url = f"/expenses?company_id=eq.{company_id}&select=amount,category&date=gte.{start_date}&date=lt.{end_date}"
    curr_response = await client.get(curr_url)
    if curr_response.status_code >= 400:
        raise HTTPException(status_code=curr_response.status_code, detail=curr_response.text)
    
    curr_expenses = curr_response.json()
    
    # Fetch previous month expenses
    prev_url = f"/expenses?company_id=eq.{company_id}&select=amount&date=gte.{prev_start_date}&date=lt.{prev_end_date}"
    prev_response = await client.get(prev_url)
    if prev_response.status_code >= 400:
        raise HTTPException(status_code=prev_response.status_code, detail=prev_response.text)
        
    prev_expenses = prev_response.json()

    # Calculate
    total_spend = sum(e['amount'] for e in curr_expenses)
    prev_spend = sum(e['amount'] for e in prev_expenses)
    
    categories = defaultdict(float)
    for e in curr_expenses:
        categories[e['category']] += e['amount']

    return {
        "month": month,
        "year": year,
        "total_spend": total_spend,
        "previous_month_spend": prev_spend,
        "categories": dict(categories)
    }

@router.post("/email")
async def send_report_email(
    request: EmailRequest,
    token: str = Depends(get_auth_token)
):
    month_name = datetime.date(request.year, request.month, 1).strftime('%B')
    
    cat_html = "".join([f"<li><strong>{k}:</strong> ₹{v:.2f}</li>" for k, v in request.categories.items()])
    
    html = f"""
    <h2>PocketLedger Monthly Analysis</h2>
    <p>Here is your expense report for <strong>{month_name} {request.year}</strong>.</p>
    
    <h3>Summary</h3>
    <ul>
        <li><strong>Total Spend:</strong> ₹{request.total_spend:.2f}</li>
        <li><strong>Previous Month Spend:</strong> ₹{request.previous_month_spend:.2f}</li>
    </ul>
    
    <h3>Categories</h3>
    <ul>
        {cat_html if cat_html else "<li>No expenses this month!</li>"}
    </ul>
    """
    
    try:
        r = resend.Emails.send({
            "from": "PocketLedger <onboarding@resend.dev>",
            "to": [request.to_email],
            "subject": f"PocketLedger Report: {month_name} {request.year}",
            "html": html
        })
        return {"status": "success", "id": r["id"]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
