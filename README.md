## QueuePlatform
    Easy to use platform for handling queues.
    Comes with a discord bot which can be configured,
    and for users to join / leave / clear / show, the queue
    
## Technology
    QueuePlatform uses python as the backend, and flutter
    in the frontend, which compiles to javascript (from dart).
    At the core of the api, we use FastAPI, alongside websockets.
    The discord api is being used (the discord.py api wrapper).
    
    
## Roadmap
    - Add a build for desktops
    - Upgrade the load to support live websocket connections
      for *everyone*, and not only the guild owner.
        