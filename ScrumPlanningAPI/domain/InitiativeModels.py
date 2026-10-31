# domain/entities/InitiativeModels.py
from pydantic import BaseModel
from datetime import date, datetime
from typing import Optional

class InitiativeBase(BaseModel):
    initiativeId: int
    initiativeSummary: str
    initiativeDescription: str
    initiativeOwner: int
    initiativeGoals: Optional[str] = None
    initiativeBusinessValue: int
    initiativeTargetStart: Optional[date] = None
    initiativeTargetEnd: Optional[date] = None
    initiativeCreationDate: datetime
    initiativeCreatorId: int
    initiativeModificationDate: Optional[datetime] = None
    initiativeModificatorId: Optional[int] = None
    initiativeStatus: int

class InitiativeCreate(BaseModel):
    initiativeSummary: str
    initiativeDescription: str
    initiativeOwnerId: int
    initiativeGoals: Optional[str] = None
    initiativeBusinessValueId: int
    initiativeTargetStart: Optional[date] = None
    initiativeTargetEnd: Optional[date] = None
    initiativeCreatorId: int
    initiativeStatusId: int

class InitiativeUpdate(BaseModel):
    initiativeId: int
    initiativeSummary: Optional[str] = None
    initiativeDescription: Optional[str] = None
    initiativeOwnerId: Optional[int] = None
    initiativeGoals: Optional[str] = None
    initiativeBusinessValueId: Optional[int] = None
    initiativeTargetStart: Optional[date] = None
    initiativeTargetEnd: Optional[date] = None
    initiativeModificatorId: int
    initiativeStatusId: Optional[int] = None