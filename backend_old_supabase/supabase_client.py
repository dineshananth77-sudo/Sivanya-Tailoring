import os
from pathlib import Path
from dotenv import load_dotenv
from supabase import create_client, Client

# Always resolve .env relative to the backend directory
env_path = Path(__file__).resolve().parent / ".env"
load_dotenv(dotenv_path=env_path)

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    raise ValueError("Supabase credentials are missing in .env")

supabase: Client = create_client(
    SUPABASE_URL,
    SUPABASE_KEY
)