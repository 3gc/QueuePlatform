import os
import secrets
from typing import Dict, List, Set

from dotenv import load_dotenv

from common.queue import GuildContainer, Queue
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

load_dotenv('.env')

# API


PROJECT_NAME = 'QueuePlatform'

app = FastAPI(
    title=PROJECT_NAME,
    # Dont' need an api documentation for this project..
    docs_url=None,
    openapi_url=None
)


origins = [
    "*"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# discord.Bot and queue stuff

WITH_BOT: bool = True

BOT_KEY_BITS = 256
BOT_KEY_BYTES = int(256 / 8)  # in this context, this is ok.

BOT_TOKEN: str = os.getenv('BOT_TOKEN')
BOT_PREFIXES = ['!queue ', '!q ']
BOT_SHOW_QUEUE_COOLDOWN = 30  # seconds


ALLOWED_GUILDS: Set[int] = {
    833078570090758224,
    516448471243292684,
}

queues: Dict[int, GuildContainer] = dict()

# Maps a discord.Guild.id to a discord.Guild.name
# (no need to store the whole discord.Guild object)
guild_names: Dict[int, str] = dict()


def get_from_queues_l(id: int, name: str) -> Queue:
    """Lazily adds a Queue object to *queues"""
    gc = queues.get(id)
    if gc is not None:
        return gc

    gc = GuildContainer(
        Queue.new(),
        secrets.token_urlsafe(BOT_KEY_BYTES)
    )

    queues[id] = gc
    guild_names[id] = name

    return gc


BOT_HELP_STR = \
    """
QueuePlatform | Discord Bot

```
prefix: `!queue`

(* = optional parameters)
```

**Queue commands**

Add yourself to the queue
- `add (value)`

List the queue
- `show (user*)`

Remove yourself from the queue
- `leave`

**Admin commands**

Remove user from queue
- `remove (user)`

"""
