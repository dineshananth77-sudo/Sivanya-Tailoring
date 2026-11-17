
from security.jwt_handler import create_access_token, verify_access_token

customer_id = "d83272ef-9c7e-42b9-afaa-c43b37366256"

token = create_access_token(customer_id)

print("Token generated:", bool(token))

verified_id = verify_access_token(token)

print("Verified customer ID:", verified_id)

print("Invalid token test:", verify_access_token("invalid-token"))
