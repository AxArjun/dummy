import asyncio
from app.core.database import _write_engine, Base
from app.models.models import *

async def main():
    async with _write_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print('Tables created!')

if __name__ == '__main__':
    asyncio.run(main())
