from typing import Optional
from pydantic import BaseModel
from datetime import date
from app.schemas.user_schema import UserOut
class StudentBase(BaseModel):
    alias: str
    safe_contact: str

class StudentCreate(StudentBase):
    user_id: int

class StudentUpdate(StudentBase):
    pass

class StudentGet(StudentBase):
    id: int
    user_id: int

class StudentCreateOut(StudentBase):
    id: int  
    user_id: int  

class StudentOut(StudentBase):
    id: int
    user: UserOut #igual a los objetos de model
    class Config:
        from_attributes = True
