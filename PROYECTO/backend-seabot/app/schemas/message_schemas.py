from pydantic import BaseModel
from typing import Optional
from datetime import date, datetime
from app.schemas.conversation_schemas import ConversationOut
class MessageBase(BaseModel):
    conversation_id: int
    role: str
    content: str

class MessageCreate(MessageBase):
    response_id: str | None = None
    fecha_hora: datetime | None = None
    score: float | None = None
    magnitude: float | None = None
    category: str | None = None
    
class MessageInput(BaseModel):
    role: str
    content: str
    conversation_id: int
    openai_id: str
    fecha_hora: datetime | None = None
    response_id: str | None = None
    

class MessageUpdate(MessageBase):
    pass

class MessageOut(MessageBase):
    id: int
    fecha_hora: datetime
    response_id: str | None = None
    class Config:
        from_attributes = True


class MessageOutDebug(BaseModel):
    student_id: int
    alias: str
    assistant_message: MessageOut
    ultimo_phq9: dict | None
    ultimo_emocional: dict | None
