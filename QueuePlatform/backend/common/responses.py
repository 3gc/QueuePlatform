from typing import Any, Dict
from fastapi.responses import JSONResponse


class SuccessResponse(JSONResponse):
    def __init__(self, detail, data=dict(), status_code=200) -> None:
        super().__init__(
            status_code=status_code,
            content={
                'error': dict(),
                'data': data,
                'detail': detail
            },
        )
