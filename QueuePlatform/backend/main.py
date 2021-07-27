import asyncio

from typing import Optional


from fastapi import Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from common.responses import SuccessResponse
from common.queue import GuildContainer
from ctx import app, WITH_BOT, BOT_TOKEN, queues, guild_names
from bot import bot


# If we don't do this the websocket endpoint will
# never be created, thus returning 403 on ws://www.api/ws
from resources import ws

templates = Jinja2Templates(directory="web")


@ app.on_event('startup')
async def startup_event() -> None:
    if WITH_BOT:
        bot.client = bot.get_client()
        asyncio.create_task(bot.client.start(BOT_TOKEN))


@ app.get('/', response_class=HTMLResponse)
async def home(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})


@app.get('/guilds', response_class=SuccessResponse)
async def get_guilds() -> SuccessResponse:

    return SuccessResponse(
        'Success',
        data=dict(
            guilds=[
                # Need to cast id_ to string, because of the json max integer limit..
                {'id': str(id_), 'name': guild_names.get(id_), 'entities': len(q.queue)} for id_, q in queues.items()]
        )
    )


@ app.get('/guild/{guild_id}/entities', response_class=SuccessResponse)
async def get_entities(guild_id: int) -> SuccessResponse:
    gc: Optional[GuildContainer] = queues.get(guild_id)

    if gc is None:
        return SuccessResponse('Invalid guild', dict(entities=list()))

    return SuccessResponse(
        'Entities',
        data=dict(
            entities=[
                e.to_json() for e in gc.queue.get(20)
            ],
            total=len(gc.queue)
        )
    )


@app.get('/check')
async def check_key(guild_id: int, key: str) -> SuccessResponse:
    gc: Optional[GuildContainer] = queues.get(guild_id)
    if gc is None:
        return SuccessResponse('', dict(valid=False))

    return SuccessResponse(
        '',
        data=dict(valid=key == gc.key)
    )


#  mounting the static directory at the end,
# will ensure that all the endpoints are loaded before
# the requests are handled over to the static file service.
# Otherwise, we will only see 404 upon requesting anything else which is not present
# in the static folder.

app.mount("/", StaticFiles(directory="web", html=True), name="web")
