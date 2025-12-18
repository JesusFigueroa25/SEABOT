from pydantic import BaseModel
from datetime import date, datetime
from app.schemas.conversation_schemas import ConversationOut
class SummaryBase(BaseModel):
    start_message_id: int
    end_message_id: int
    resumen: str
    fecha_hora: datetime

class SummaryCreate(SummaryBase):
    conversation_id: int

class SummaryUpdate(SummaryBase):
    pass

class SummaryOut(SummaryBase):
    id: int
    conversation: ConversationOut #igual a los objetos de model
    class Config:
        from_attributes = True
