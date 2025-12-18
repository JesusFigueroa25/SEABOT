from pydantic import BaseModel
from datetime import date, datetime
from app.schemas.student_schema import StudentOut
class DiaryEntryBase(BaseModel):
    entry: str
    fecha_hora: datetime

class DiaryEntryCreate(DiaryEntryBase):
    student_id: int

class DiaryEntryUpdate(DiaryEntryBase):
    pass

class DiaryEntryGet(DiaryEntryBase):
    id: int
    student_id: int

class DiaryEntryOut(DiaryEntryBase):
    id: int
    student: StudentOut #igual a los objetos de model
    class Config:
        from_attributes = True
