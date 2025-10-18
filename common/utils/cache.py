import aioredis
from common.config import settings

async def get_redis():
    return await aioredis.from_url(settings.REDIS_URL)
