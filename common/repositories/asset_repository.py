from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from uuid import UUID
from common.models.asset import Asset
from common.schemas.asset_schema import AssetCreate, AssetUpdate


async def create_asset(db: AsyncSession, asset: AssetCreate) -> Asset:
    db_obj = Asset(**asset.dict())
    db.add(db_obj)
    await db.commit()
    await db.refresh(db_obj)
    return db_obj


async def get_asset(db: AsyncSession, asset_id: UUID) -> Asset:
    stmt = select(Asset).filter(Asset.id == asset_id)
    result = await db.execute(stmt)
    return result.scalars().first()


async def get_assets(db: AsyncSession, skip: int = 0, limit: int = 100):
    stmt = select(Asset).offset(skip).limit(limit)
    result = await db.execute(stmt)
    return result.scalars().all()


async def update_asset(db: AsyncSession, asset_id: UUID, asset: AssetUpdate) -> Asset | None:
    stmt = select(Asset).filter(Asset.id == asset_id)
    result = await db.execute(stmt)
    db_obj = result.scalars().first()
    if db_obj:
        for key, value in asset.dict(exclude_unset=True).items():
            setattr(db_obj, key, value)
        await db.commit()
        await db.refresh(db_obj)
    return db_obj


async def delete_asset(db: AsyncSession, asset_id: UUID) -> None:
    stmt = select(Asset).filter(Asset.id == asset_id)
    result = await db.execute(stmt)
    db_obj = result.scalars().first()
    if db_obj:
        await db.delete(db_obj)
        await db.commit()
