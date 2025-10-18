from fastapi import FastAPI
from app.routes import asset_routes

app = FastAPI(title='Neuro AI API')
app.include_router(asset_routes.router, prefix='/api/assets', tags=['Assets'])