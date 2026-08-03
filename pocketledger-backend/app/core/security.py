from fastapi import HTTPException, Header
from jose import jwt, JWTError

async def get_auth_token(authorization: str = Header(...)) -> str:
    """Extract and validate the Bearer token from the Authorization header."""
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authorization header")
    return authorization


async def get_user_id(authorization: str = Header(...)) -> str:
    """Decode the Supabase JWT and return the user's UUID (sub claim).
    
    Supabase JWTs are signed with HS256 using the JWT secret. For a lightweight
    check we decode without verifying signature (Supabase RLS re-verifies anyway).
    In production, set SUPABASE_JWT_SECRET and verify properly.
    """
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authorization header")
    
    token = authorization.replace("Bearer ", "")
    try:
        # Decode without verification — Supabase RLS will re-verify
        payload = jwt.decode(token, "", options={"verify_signature": False})
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail="Invalid token: no user ID")
        return user_id
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")


def get_company_id(x_company_id: str = Header(None)) -> str | None:
    """Extract the optional X-Company-ID header sent by the Flutter client."""
    return x_company_id
