from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import transactions, reports, companies

app = FastAPI(title="PocketLedger Backend", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(transactions.router, prefix="/api/transactions", tags=["Transactions"])
app.include_router(reports.router, prefix="/api/reports", tags=["Reports"])
app.include_router(companies.router, prefix="/api/companies", tags=["Companies"])

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
