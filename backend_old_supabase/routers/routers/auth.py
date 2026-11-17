
from uuid import UUID

from fastapi import APIRouter, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, EmailStr, Field

from supabase_client import supabase
from security.password import hash_password, verify_password
from security.jwt_handler import create_access_token, verify_access_token


router = APIRouter(
    prefix="/auth",
    tags=["Authentication"]
)

security = HTTPBearer()


# Signup request
class SignupRequest(BaseModel):
    full_name: str = Field(min_length=2, max_length=100)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    phone: str | None = None


# Login request
class LoginRequest(BaseModel):
    email: EmailStr
    password: str


# Signup
@router.post("/signup")
def signup(data: SignupRequest):

    email = str(data.email).lower()

    existing = (
        supabase.table("customers")
        .select("id")
        .eq("email", email)
        .execute()
    )

    if existing.data:
        raise HTTPException(
            status_code=409,
            detail="Email already registered"
        )

    password_hash = hash_password(data.password)

    response = (
        supabase.table("customers")
        .insert({
            "full_name": data.full_name,
            "email": email,
            "password_hash": password_hash,
            "phone": data.phone
        })
        .execute()
    )

    if not response.data:
        raise HTTPException(
            status_code=500,
            detail="Registration failed"
        )

    customer = response.data[0]

    token = create_access_token(str(customer["id"]))

    return {
        "message": "Registration successful",
        "access_token": token,
        "token_type": "bearer",
        "customer": {
            "id": customer["id"],
            "full_name": customer["full_name"],
            "email": customer["email"],
            "phone": customer["phone"]
        }
    }


# Login
@router.post("/login")
def login(data: LoginRequest):

    email = str(data.email).lower()

    response = (
        supabase.table("customers")
        .select("*")
        .eq("email", email)
        .execute()
    )

    if not response.data:
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )

    customer = response.data[0]

    if not customer["is_active"]:
        raise HTTPException(
            status_code=403,
            detail="Account is inactive"
        )

    if not verify_password(
        data.password,
        customer["password_hash"]
    ):
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )

    token = create_access_token(str(customer["id"]))

    return {
        "message": "Login successful",
        "access_token": token,
        "token_type": "bearer",
        "customer": {
            "id": customer["id"],
            "full_name": customer["full_name"],
            "email": customer["email"],
            "phone": customer["phone"]
        }
    }


# Get currently logged-in customer
def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
):

    token = credentials.credentials

    customer_id = verify_access_token(token)

    if customer_id is None:
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired token"
        )

    try:
        customer_uuid = str(UUID(customer_id))
    except ValueError:
        raise HTTPException(
            status_code=401,
            detail="Invalid customer ID in token"
        )

    response = (
        supabase.table("customers")
        .select("id, full_name, email, phone, is_active")
        .eq("id", customer_uuid)
        .execute()
    )

    if not response.data:
        raise HTTPException(
            status_code=401,
            detail="Customer not found"
        )

    customer = response.data[0]

    if not customer["is_active"]:
        raise HTTPException(
            status_code=403,
            detail="Account is inactive"
        )

    return customer


# Customer profile
@router.get("/me")
def get_my_profile(
    user=Depends(get_current_user)
):
    return user
