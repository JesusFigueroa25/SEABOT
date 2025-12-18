from pydantic import BaseModel
from datetime import date, datetime
from app.schemas.student_schema import StudentOut
class ConversationBase(BaseModel):
    openai_id: str
    name_conversation: str
    qualification: int
    fecha_inicio: datetime
    enable: bool

class ConversationCreate(ConversationBase):
    student_id: int

class ConversationUpdate(ConversationBase):
    pass

class ConversationOut(ConversationBase):
    id: int
    student: StudentOut #igual a los objetos de model
    class Config:
        from_attributes = True

#Funcionalidades
class ConversationGet(BaseModel):
    openai_id: str
    name_conversation: str
    qualification: int
    fecha_inicio: datetime
    id: int

class ConversationUpdateName(BaseModel):
    name_conversation: str
    
class ConversationUpdateCal(BaseModel):
    qualification: int
    
class ConversationCreateOpenAI(BaseModel):
    student_id: int
    
class ConversationOpenAIOut(ConversationBase):
    id: int
    class Config:
        from_attributes = True  