from typing import Optional
from pydantic import BaseModel
from datetime import date
#from app.schemas.student_schema import StudentOut
class HelpResourceBase(BaseModel):
    name_resource: str
    enable: bool

class HelpResourceCreate(HelpResourceBase):
    description: Optional[str] = None
    resource_type: Optional[str] = None
    url: Optional[str] = None

class HelpResourceGet(HelpResourceBase):
    pass

class HelpResourceUpdate(HelpResourceBase):
    description: Optional[str] = None
    resource_type: Optional[str] = None
    url: Optional[str] = None

class HelpResourceEnable(BaseModel):
    enable: bool

class HelpResourceOut(HelpResourceBase):
    id: int
    description: str 
    resource_type: str
    url: str
    class Config:
        from_attributes = True
