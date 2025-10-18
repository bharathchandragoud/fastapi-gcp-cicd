from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from enum import Enum
from uuid import UUID


class AssetTypeEnum(str, Enum):
    img = "img"
    video = "video"
    audio = "audio"

class AssetBase(BaseModel):
    store_id: UUID
    asset_type: AssetTypeEnum
    prompt: str
    negative_prompt: Optional[str] = None
    seed: Optional[int] = None
    steps: Optional[int] = None
    sampler: Optional[str] = None
    guidance_scale: Optional[float] = None

    class Config:
        orm_mode = True
        arbitrary_types_allowed = True
        from_attributes = True

class AssetCreate(AssetBase):
    pass

class AssetUpdate(AssetBase):
    pass

class AssetRead(AssetBase):
    id: UUID
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True
        arbitrary_types_allowed = True
