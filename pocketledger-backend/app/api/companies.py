from fastapi import APIRouter, Depends, HTTPException
import httpx
from app.core.config import settings
from app.core.security import get_auth_token, get_company_id
from app.models.schemas import CompanyCreate, CompanyMemberAdd

router = APIRouter()

@router.post("")
async def create_company(company: CompanyCreate, token: str = Depends(get_auth_token)):
    headers = {
        "apikey": settings.SUPABASE_ANON_KEY,
        "Authorization": token,
        "Prefer": "return=representation",
        "Content-Type": "application/json"
    }
    async with httpx.AsyncClient() as client:
        url = f"{settings.SUPABASE_URL}/rest/v1/companies"
        response = await client.post(url, headers=headers, json=company.dict())
        if response.status_code >= 400:
            raise HTTPException(status_code=response.status_code, detail=response.text)
        return response.json()[0]

@router.get("")
async def get_companies(token: str = Depends(get_auth_token)):
    headers = {
        "apikey": settings.SUPABASE_ANON_KEY,
        "Authorization": token,
    }
    async with httpx.AsyncClient() as client:
        url = f"{settings.SUPABASE_URL}/rest/v1/companies?select=*"
        response = await client.get(url, headers=headers)
        if response.status_code >= 400:
            raise HTTPException(status_code=response.status_code, detail=response.text)
        return response.json()
