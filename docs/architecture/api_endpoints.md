# PocketLedger — API Documentation

This document describes the endpoints provided by the **FastAPI Backend Service**. 

## 🔒 Global Configuration

### Base URL
*   **Local Development:** `http://localhost:8000` (or `http://10.0.2.2:8000` for Android Emulator)
*   **Production:** Publicly hosted domain (e.g., Render or Vercel instance)

### Required Headers
Every authenticated API request must include the following headers:

| Header | Type | Description | Required |
|---|---|---|---|
| `Authorization` | String | Must follow format: `Bearer <SUPABASE_JWT_TOKEN>` | Yes |
| `X-Company-ID` | String (UUID) | The active company workspace identifier | Yes (For Transactions and Reports) |

---

## 💼 1. Companies / Workspaces API (`/api/companies`)

Endpoints for managing shared multi-tenant workspaces.

### **Fetch User's Workspaces**
*   **Method:** `GET`
*   **Endpoint:** `/api/companies`
*   **Response (200 OK):**
    ```json
    [
      {
        "id": "e0b57e4e-0a56-42d8-9be5-9f5b08c6de64",
        "name": "Bhawuk's Startup",
        "created_at": "2026-08-04T12:00:00Z"
      }
    ]
    ```

### **Create a Workspace**
*   **Method:** `POST`
*   **Endpoint:** `/api/companies`
*   **Request Body:**
    ```json
    {
      "name": "Personal Workspace"
    }
    ```
*   **Response (200 OK):**
    ```json
    {
      "id": "e0b57e4e-0a56-42d8-9be5-9f5b08c6de64",
      "name": "Personal Workspace",
      "created_at": "2026-08-04T12:05:00Z"
    }
    ```

---

## 💸 2. Transactions API (`/api/transactions`)

CRUD operations for tracking expenses scoped under the current `X-Company-ID` workspace header.

### **Get Transactions**
Retrieves expenses with pagination and optional monthly filtering.
*   **Method:** `GET`
*   **Endpoint:** `/api/transactions`
*   **Query Parameters:**
    *   `limit` (integer, default: 30) - Number of records to return.
    *   `offset` (integer, default: 0) - Pagination offset.
    *   `month` (integer, optional) - Target month filter (1-12).
    *   `year` (integer, optional) - Target year filter.
*   **Response (200 OK):**
    ```json
    [
      {
        "id": "78abec32-84bb-42c2-bdf4-f584e03d42fb",
        "company_id": "e0b57e4e-0a56-42d8-9be5-9f5b08c6de64",
        "amount": 250.00,
        "category": "Food",
        "place": "Haldiram's",
        "notes": "Rajma Chawal lunch",
        "date": "2026-08-04T13:10:00Z"
      }
    ]
    ```

### **Create Transaction**
*   **Method:** `POST`
*   **Endpoint:** `/api/transactions`
*   **Request Body:**
    ```json
    {
      "amount": 250.00,
      "category": "Food",
      "place": "Haldiram's",
      "notes": "Rajma Chawal lunch",
      "date": "2026-08-04T13:10:00Z"
    }
    ```
*   **Response (200 OK):**
    ```json
    {
      "id": "78abec32-84bb-42c2-bdf4-f584e03d42fb",
      "company_id": "e0b57e4e-0a56-42d8-9be5-9f5b08c6de64",
      "amount": 250.00,
      "category": "Food",
      "place": "Haldiram's",
      "notes": "Rajma Chawal lunch",
      "date": "2026-08-04T13:10:00Z"
    }
    ```

### **Update Transaction**
*   **Method:** `PUT`
*   **Endpoint:** `/api/transactions/{transaction_id}`
*   **Request Body:** (All fields are optional)
    ```json
    {
      "amount": 300.00,
      "category": "Food"
    }
    ```
*   **Response (200 OK):** Updates the entry in Supabase REST and returns the patched record.

### **Delete Transaction**
*   **Method:** `DELETE`
*   **Endpoint:** `/api/transactions/{transaction_id}`
*   **Response (200 OK):**
    ```json
    {
      "status": "success"
    }
    ```

---

## 📊 3. Reports API (`/api/reports`)

Endpoints for compiling analytics and sending alerts.

### **Get Monthly Analysis**
*   **Method:** `GET`
*   **Endpoint:** `/api/reports/monthly`
*   **Query Parameters:**
    *   `month` (integer, required) - e.g., 8
    *   `year` (integer, required) - e.g., 2026
*   **Response (200 OK):**
    ```json
    {
      "month": 8,
      "year": 2026,
      "total_spend": 32000.50,
      "previous_month_spend": 28000.00,
      "categories": {
        "Food": 12000.00,
        "Transport": 4500.50,
        "Shopping": 15500.00
      }
    }
    ```

### **Send Report Email**
Triggers a formatted HTML report email dispatch to the recipient using the **Resend API**.
*   **Method:** `POST`
*   **Endpoint:** `/api/reports/email`
*   **Request Body:**
    ```json
    {
      "to_email": "bhawuk@example.com",
      "month": 8,
      "year": 2026,
      "total_spend": 32000.50,
      "previous_month_spend": 28000.00,
      "categories": {
        "Food": 12000.00,
        "Transport": 4500.50,
        "Shopping": 15500.00
      }
    }
    ```
*   **Response (200 OK):**
    ```json
    {
      "status": "success",
      "id": "e04df7ac-c711-48bd-b7bb-5e58129df4cc"
    }
    ```
