from collections import UserList
from typing import Dict, List, Union


class QueueEntity(object):

    __slots__ = 'id', 'value', 'tier'

    def __init__(
        self,
        id: int,
        value: str,
        tier: int,
    ) -> None:
        self.id, self.value, self.tier = id, value, tier

    def to_json(self) -> Dict[str, Union[str, int]]:
        return dict(
            id=str(self.id),
            value=self.value,
            tier=self.tier
        )


class Queue(UserList):
    def __init__(
        self,
        queue: List[QueueEntity],
        max_entities=None
    ) -> None:
        super().__init__(queue)
        self.max_entities = max_entities

    @ classmethod
    def new(cls, **options) -> 'Queue':
        return Queue(
            queue=[],
            **options
        )

    def pop(self, index: int) -> None:
        try:
            return self.data.pop(index)
        except IndexError:
            pass

    def entities(self) -> List[QueueEntity]:
        return self.data

    def append(self, entity: QueueEntity) -> None:
        if self.max_entities is None:
            return self.data.append(entity)

        if not (len(self.data) >= self.max_entities):
            return self.data.append(entity)

    def push(self, pos: int, amount: int = 1):
        try:
            self.data.insert(pos+amount, self.data.pop(pos))
        except IndexError:
            return None

    def get(self, amount: int, offset: int = 0) -> List[QueueEntity]:
        try:
            return self.data[offset:amount]
        except IndexError:
            return list()

    def clear(self):
        self.data.clear()

    def get_at(self, index: int):
        try:
            return self.data[index]
        except IndexError:
            return None


class GuildContainer:
    __slots__ = 'queue', 'key'

    def __init__(self, queue: Queue, key: str):
        self.queue = queue
        self.key = key
