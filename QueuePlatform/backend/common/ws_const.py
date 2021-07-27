import asyncio
from typing import Any, Dict, Optional


events: Dict[str, asyncio.Queue] = dict()


async def push_event(target: int, event: Dict[str, Any]) -> None:
    """Pushes the event if the target guild has an open ws connection"""
    q: Optional[asyncio.Queue] = events.get(target)
    if q is not None:
        await q.put(event)
