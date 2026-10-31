from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class TaskCommentBase(BaseModel):
    taskCommentId: int
    taskCommentParentLink: int
    taskCommentOwner: int
    taskCommentText: str
    taskCommentCreationDate: datetime
    taskCommentCreatorId: int
    taskCommentModificationDate: Optional[datetime] = None
    taskCommentModificatorId: Optional[int] = None
    taskCommentStatus: bool

class TaskCommentCreate(BaseModel):
    taskCommentParentLink: int
    taskCommentOwner: int
    taskCommentText: str
    taskCommentCreatorId: int

class TaskCommentUpdate(BaseModel):
    taskCommentId: int
    taskCommentText: Optional[str] = None
    taskCommentModificatorId: int
    taskCommentStatus: Optional[bool] = None