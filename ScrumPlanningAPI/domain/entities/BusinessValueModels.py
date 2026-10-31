# domain/entities/BusinessValueModels.py
from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class BusinessValueBase(BaseModel):
    businessValueId: int
    businessValueName: str
    businessValueCreationDate: datetime
    businessValueCreatorId: int
    businessValueModificationDate: Optional[datetime] = None
    businessValueModificatorId: Optional[int] = None
    businessValueEnable: bool

class BusinessValueCreate(BaseModel):
    businessValueName: str
    businessValueCreatorId: int

class BusinessValueUpdate(BaseModel):
    businessValueId: int
    businessValueName: Optional[str] = None
    businessValueModificatorId: int
    businessValueEnable: Optional[bool] = None