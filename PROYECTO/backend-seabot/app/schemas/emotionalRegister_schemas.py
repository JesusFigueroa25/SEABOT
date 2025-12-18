from pydantic import BaseModel
from datetime import date, datetime
from app.schemas.student_schema import StudentOut
class EmotionalRegisterBase(BaseModel):
    emotion: str
    fecha_hora: datetime

class EmotionalRegisterCreate(EmotionalRegisterBase):
    student_id: int

class EmotionalRegisterUpdate(EmotionalRegisterBase):
    pass

class EmotionalRegisterGet(EmotionalRegisterBase):
    id: int
    student_id: int

class EmotionalRegisterOut(EmotionalRegisterBase):
    id: int
    student: StudentOut #igual a los objetos de model
    class Config:
        from_attributes = True
