from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class PriorityBase(BaseModel):
    priorityId: int
    priorityName: str
    priorityCreationDate: datetime
    priorityCreatorId: int
    priorityModificationDate: Optional[datetime] = None
    priorityModificatorId: Optional[int] = None
    priorityEnable: bool

class PriorityCreate(BaseModel):
    priorityName: str
    priorityCreatorId: int

class PriorityUpdate(BaseModel):
    priorityId: int
    priorityName: Optional[str] = None
    priorityModificatorId: int
    priorityEnable: Optional[bool] = None