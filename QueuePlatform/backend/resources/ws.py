
import asyncio
from typing import Any, Dict, Optional
from fastapi import WebSocket, status
from common.queue import GuildContainer, Queue, QueueEntity


from ctx import app, queues
from common.ws_const import events

CODE = status.WS_1008_POLICY_VIOLATION


async def events_queue_listener(websocket: WebSocket, guild_id: int) -> None:
    try:
        while events.get(guild_id):

            event = await events[guild_id].get()
            await websocket.send_json(event)
    except Exception:
        return


async def process_event(queue: Queue, data: Dict[str, Any]):

    event = data.get('event')
    target = data.get('target')
    if target.isdigit():
        target = int(target)
    if event == 'remove' and isinstance(target, int):
        for i, e in enumerate(queue.entities()):
            if e.id == target:
                queue.pop(i)


@app.websocket('/ws')
async def new_ws(websocket: WebSocket, guild_id: int, key: str):
    gc: Optional[GuildContainer] = queues.get(guild_id)
    if gc is None or gc.key != key:
        return await websocket.close(CODE)

    try:
        await websocket.accept()
        events[guild_id] = asyncio.Queue()
        _ = asyncio.gather(events_queue_listener(websocket, guild_id))

        async for data in websocket.iter_json():
            await process_event(gc.queue, data)
    except Exception as e:
        del events[guild_id]
