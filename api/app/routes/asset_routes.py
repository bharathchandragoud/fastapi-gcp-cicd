from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID
from typing import List
from common.db.session import get_session
from common.schemas.asset_schema import AssetRead, AssetCreate, AssetUpdate
import common.repositories.asset_repository as repo
from fastapi import status, HTTPException

router = APIRouter()

@router.post("/", response_model=AssetRead, status_code=status.HTTP_201_CREATED)
async def create(asset: AssetCreate, db: AsyncSession = Depends(get_session)):
    return await repo.create_asset(db, asset)

@router.get("/{asset_id}", response_model=AssetRead, status_code=status.HTTP_200_OK)
async def read(asset_id: UUID, db: AsyncSession = Depends(get_session)):
    db_asset = await repo.get_asset(db, asset_id)
    if not db_asset:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Asset not found")
    return db_asset

@router.get("/", response_model=List[AssetRead], status_code=status.HTTP_200_OK)
async def read_all(skip: int = 0, limit: int = 100, db: AsyncSession = Depends(get_session)):
    return await repo.get_assets(db, skip, limit)

@router.put("/{asset_id}", response_model=AssetRead, status_code=status.HTTP_200_OK)
async def update(asset_id: UUID, asset: AssetUpdate, db: AsyncSession = Depends(get_session)):
    db_asset = await repo.update_asset(db, asset_id, asset)
    if not db_asset:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Asset not found")
    return db_asset

@router.delete("/{asset_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete(asset_id: UUID, db: AsyncSession = Depends(get_session)):
    await repo.delete_asset(db, asset_id)
    return None
