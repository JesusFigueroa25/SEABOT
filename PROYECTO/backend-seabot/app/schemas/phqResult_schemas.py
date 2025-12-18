from pydantic import BaseModel
from datetime import date, datetime
from app.schemas.student_schema import StudentOut
class PhqResultBase(BaseModel):
    total_score: int
    interpretation: str
    fecha: date

class PhqResultCreate(PhqResultBase):
    student_id: int

class PhqResultUpdate(PhqResultBase):
    pass

class PhqResultGetPhq(PhqResultBase):
    id: int
    student_id: int

class PhqResultOut(PhqResultBase):
    id: int
    student: StudentOut #igual a los objetos de model
    class Config:
        from_attributes = True
