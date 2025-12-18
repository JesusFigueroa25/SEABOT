from sqlalchemy import Column, Integer, String, Float, ForeignKey, Boolean, Date, DateTime,Text
from sqlalchemy.orm import relationship
from app.database.database import Base


class Summary(Base):
    __tablename__ = "summaries"

    id = Column(Integer, primary_key=True, index=True)
    conversation_id = Column(Integer, ForeignKey("conversations.id", ondelete="CASCADE"), nullable=False)
    start_message_id = Column(Integer)  
    end_message_id = Column(Integer)  
    resumen = Column(Text)  
    fecha_hora = Column(DateTime)

    conversation = relationship("Conversation", back_populates="sumaries")
