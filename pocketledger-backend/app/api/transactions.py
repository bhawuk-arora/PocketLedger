from fastapi import APIRouter, Depends, HTTPException, Header
import httpx
from app.core.config import settings
from app.core.security import get_auth_token, get_company_id
from app.models.schemas import ExpenseCreate, ExpenseUpdate

router = APIRouter()

async def get_supabase_client(token: str = Depends(get_auth_token)):
    headers = {
        "apikey": settings.SUPABASE_ANON_KEY,
        "Authorization": token,
        "Prefer": "return=representation",
        "Content-Type": "application/json"
    }
    return httpx.AsyncClient(headers=headers, base_url=f"{settings.SUPABASE_URL}/rest/v1")

@router.get("")
async def get_transactions(
    limit: int = 30, 
    offset: int = 0, 
    month: int = None, 
    year: int = None,
    client: httpx.AsyncClient = Depends(get_supabase_client),
    company_id: str | None = Depends(get_company_id)
):
    if not company_id:
        raise HTTPException(status_code=400, detail="X-Company-ID header is required")
        
    url = f"/expenses?company_id=eq.{company_id}&select=*&order=date.desc&limit={limit}&offset={offset}"
    
    if month and year:
        start_date = f"{year}-{month:02d}-01T00:00:00Z"
        if month == 12:
            end_date = f"{year+1}-01-01T00:00:00Z"
        else:
            end_date = f"{year}-{month+1:02d}-01T00:00:00Z"
            
        url += f"&date=gte.{start_date}&date=lt.{end_date}"

    response = await client.get(url)
    if response.status_code >= 400:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    
    return response.json()

@router.post("")
async def create_transaction(
    expense: ExpenseCreate,
    client: httpx.AsyncClient = Depends(get_supabase_client),
    company_id: str | None = Depends(get_company_id)
):
    if not company_id:
         raise HTTPException(status_code=400, detail="X-Company-ID header is required")
         
    expense_dict = expense.dict()
    expense_dict['company_id'] = company_id
    
    response = await client.post("/expenses", json=expense_dict)
    if response.status_code >= 400:
        raise HTTPException(status_code=response.status_code, detail=response.text)
        
    return response.json()

@router.put("/{transaction_id}")
async def update_transaction(
    transaction_id: str,
    expense: ExpenseUpdate,
    client: httpx.AsyncClient = Depends(get_supabase_client),
    company_id: str | None = Depends(get_company_id)
):
    if not company_id:
        raise HTTPException(status_code=400, detail="X-Company-ID header is required")
        
    url = f"/expenses?id=eq.{transaction_id}&company_id=eq.{company_id}"
    update_data = {k: v for k, v in expense.dict().items() if v is not None}
    
    response = await client.patch(url, json=update_data)
    if response.status_code >= 400:
        raise HTTPException(status_code=response.status_code, detail=response.text)
        
    return response.json()

@router.delete("/{transaction_id}")
async def delete_transaction(
    transaction_id: str,
    client: httpx.AsyncClient = Depends(get_supabase_client),
    company_id: str | None = Depends(get_company_id)
):
    if not company_id:
        raise HTTPException(status_code=400, detail="X-Company-ID header is required")
        
    url = f"/expenses?id=eq.{transaction_id}&company_id=eq.{company_id}"
    response = await client.delete(url)
    if response.status_code >= 400:
        raise HTTPException(status_code=response.status_code, detail=response.text)
        
    return {"status": "success"}
