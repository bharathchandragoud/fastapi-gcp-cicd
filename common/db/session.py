# ===========================
# common/db/session.py (Updated with get_session alias)
# ===========================
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from sqlalchemy.orm import declarative_base
from common.config import settings

Base = declarative_base()
engine = create_async_engine(settings.DATABASE_URL, echo=False, future=True)
AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session

# ✅ Alias for backward compatibility
get_session = get_db