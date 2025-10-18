from sqlalchemy import Column, Integer, String, Float, DateTime
from sqlalchemy.sql import func
from common.db.base import Base
from common.models.enums.asset_type import AssetTypeEnum
from sqlalchemy.dialects.postgresql import UUID
import uuid
from sqlalchemy import Enum

class Asset(Base):
    __tablename__ = "asset"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, unique=True, index=True)
    store_id = Column(UUID(as_uuid=True), nullable=False)
    # asset_type = Column(SQLEnum(AssetTypeEnum), nullable=False)
    asset_type = Column(Enum(AssetTypeEnum, name='asset_type_enum'), nullable=False)
    prompt = Column(String, nullable=False)
    negative_prompt = Column(String)
    seed = Column(Integer)
    steps = Column(Integer)
    sampler = Column(String)
    guidance_scale = Column(Float)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
