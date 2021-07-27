import logging
import secrets
from typing import Optional
import discord
from discord.ext import commands
from starlette.types import Message

from ctx import ALLOWED_GUILDS, BOT_KEY_BYTES, queues, BOT_PREFIXES, get_from_queues_l, BOT_SHOW_QUEUE_COOLDOWN, BOT_HELP_STR
from common.queue import GuildContainer, Queue, QueueEntity
from common.ws_const import push_event

MAX_QUEUE_DISPLAY = 20

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def get_client(prefixes=BOT_PREFIXES, **kwargs) -> commands.Bot:

    # intents
    intents = discord.Intents.default()
    intents.members = True

    client = commands.Bot(command_prefix=prefixes,
                          intents=intents, help_command=None, **kwargs)

    client.add_cog(QueueCog(client))

    return client


async def get_queue_else_err(ctx: commands.Context) -> Optional[GuildContainer]:
    gc: Optional[GuildContainer] = queues.get(ctx.guild.id)
    if (gc is None) or not len(gc.queue):
        await ctx.send(
            embed=discord.Embed(
                title='Queue is empty',
                color=discord.Colour.red()
            )
        )
        return None

    return gc


class DefinedEmebds:
    NOT_IN_QUEUE = discord.Embed(
        color=discord.Color.red(),
        title='Error',
        description='User not in queue.'
    )

    HELP = discord.Embed(
        title='QueuePlatform | Discord Bot',
        description=BOT_HELP_STR
    )


DefinedEmebds.HELP.add_field(
    name='Source code', value='[Source](https://www.github.com/3gc/QueuePlatform)', inline=False)


class QueueCog(commands.Cog):
    def __init__(self, client) -> None:
        self.client = client

    @ commands.command(name='add', aliases=['signup'])
    async def add(self, ctx: commands.Context, value: str) -> Optional[discord.Message]:
        if not ctx.guild or (not ctx.guild.id in ALLOWED_GUILDS):
            return

        gc: GuildContainer = get_from_queues_l(ctx.guild.id, ctx.guild.name)
        queue = gc.queue

        if any(e.id == ctx.author.id for e in queue.entities()):
            return await ctx.send(
                embed=discord.Embed(
                    title='Error',
                    description='Already in queue',
                    color=discord.Colour.red()
                )
            )

        tier: int = 1
        for role in ctx.author.roles:
            if 'tier' in role.name.lower():
                try:
                    l = [x for x in role.name if x.isdigit()]
                    if l:
                        tier = int(l[0])
                except (ValueError, KeyError):
                    continue

        await push_event(ctx.guild.id, {
            'event': 'add',
            'value': value,
            'tier': tier
        })

        queue.append(QueueEntity(
            ctx.author.id,
            value,
            tier
        ))
        return await ctx.send(
            embed=discord.Embed(
                title='Success',
                description=f'{value} was added to the queue\nPosition number: `{len(queue)}`',
                color=discord.Colour.green()
            )
        )

    async def _remove_user(self, ctx: commands.Context, user: discord.User):
        gc: Optional[GuildContainer] = await get_queue_else_err(ctx)
        if gc is None:
            return

        queue: Queue = gc.queue
        await push_event(ctx.guild.id, {
            'event': 'remove',
            'target': str(ctx.author.id)
        })

        for i, e in enumerate(queue.entities()):
            if e.id == user.id:
                queue.pop(i)

                return await ctx.send(
                    embed=discord.Embed(
                        title='Success',
                        description=f'{user.name} removed from queue.',
                        color=discord.Color.green()
                    )
                )

        return await ctx.send(
            embed=DefinedEmebds.NOT_IN_QUEUE
        )

    @commands.command(name='remove', aliases=['remove_user'])
    @commands.has_permissions(administrator=True)
    async def remove_user(self, ctx,  user: discord.User):
        return await self._remove_user(ctx, user)

    @commands.command(name='clear')
    @commands.has_permissions(administrator=True)
    async def clear_queue(self, ctx):
        gc: Optional[GuildContainer] = await get_queue_else_err(ctx)

        gc.queue.clear()
        await push_event(ctx.guild.id, dict(event='clear'))

        await ctx.channel.send(
            embed=discord.Embed(
                title='Success',
                description='Queue cleared.',
                color=discord.Color.green()
            )
        )

    @commands.command()
    async def leave(self, ctx):
        return await self._remove_user(ctx, ctx.author)

    @commands.cooldown(1, BOT_SHOW_QUEUE_COOLDOWN, commands.BucketType.user)
    @commands.command(name='queue', aliases=['show', 'get'])
    async def show_queue(self, ctx, user: discord.User = None):
        if not ctx.guild or (not ctx.guild.id in ALLOWED_GUILDS):
            return

        LIMIT = 10

        gc: Optional[GuildContainer] = await get_queue_else_err(ctx)
        if gc is None:
            return
        queue: Queue = gc.queue

        if user is not None:
            positions = [i for i, e in enumerate(
                queue.entities()) if e.id == user.id]

            if not positions:
                return await ctx.send(
                    embed=DefinedEmebds.NOT_IN_QUEUE
                )

            return await ctx.send(
                embed=discord.Embed(
                    title=f'Position in queue for {user.name}',
                    description=f'`{positions[0]+1}`/{len(queue)}'
                )
            )

        items = '\n'.join([
            f'[{i+1}] {q.value}'
            for i, q in enumerate(queue.get(LIMIT))])

        await ctx.send(
            embed=discord.Embed(
                title=f'Queue, {LIMIT if LIMIT < len(queue) else len(queue)} / {len(queue)}',
                description=f"Queue Positions\n```{items}```",
                color=discord.Colour.green()
            )
        )

    @commands.command(name='info', aliases=['information', 'index'])
    async def queue_information(self, ctx, position: int):
        gc: Optional[GuildContainer] = await get_queue_else_err(ctx)
        if gc is None:
            return None

        queue: Queue = gc.queue

        entity: Optional[QueueEntity] = queue.get_at(position)
        if entity is None:
            return await ctx.send(
                embed=discord.Embed(
                    title='Error',
                    description='Invalid position.',
                    color=discord.Color.red()
                )
            )

        await ctx.send(
            embed=discord.Embed(title=f'Position: {position}',
                                description=f"""```Registered information:\nvalue: {entity.value}\ntier: {entity.tier}```
                """)
        )

    @commands.command(name='key')
    async def key(self, ctx):
        if not ctx.guild.owner or (ctx.guild.owner.id != ctx.author.id):
            return

        gc: GuildContainer = get_from_queues_l(ctx.guild.id, ctx.guild.name)

        # Generate a new key each time this command is calleds
        gc.key = secrets.token_urlsafe(BOT_KEY_BYTES)

        await ctx.author.send(
            embed=discord.Embed(
                title='Key',
                description=gc.key
            )
        )

    @commands.command(name='help')
    async def queue_help(self, ctx):
        await ctx.send(embed=DefinedEmebds.HELP)

    @ add.error
    async def queue_add_error(self, ctx, error):
        if isinstance(error, commands.MissingRequiredArgument):
            return await ctx.author.send('Invalid usage of command.')

        raise error

    @ show_queue.error
    async def show_queue_error(self, ctx, error):
        if isinstance(error, commands.CommandOnCooldown):
            return await ctx.author.send(f'You can only see the queue once every {BOT_SHOW_QUEUE_COOLDOWN} seconds.')

    @remove_user.error
    async def remove_user_error(self, ctx, error):
        if isinstance(error, commands.UserNotFound):
            return await ctx.author.send("User not found")
