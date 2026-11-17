
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers import products, auth, measurements, orders, wishlist, upload

app = FastAPI(title="Stitch & Style API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(products.router)
app.include_router(auth.router)
app.include_router(measurements.router)
app.include_router(orders.router)
app.include_router(wishlist.router)
app.include_router(upload.router)


@app.get("/")
def home():
    return {"message": "Stitch & Style API is running"}
