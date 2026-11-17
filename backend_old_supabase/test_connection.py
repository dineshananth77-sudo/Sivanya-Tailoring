
from supabase_client import supabase

try:
    response = (
        supabase.table("products")
        .select("*")
        .execute()
    )

    print("SUPABASE CONNECTION SUCCESSFUL!")
    print("Products found:", len(response.data))
    print("Product details:")

    for product in response.data:
        print(product["id"], "-", product["title"])

except Exception as error:
    print("SUPABASE CONNECTION FAILED!")
    print(error)
