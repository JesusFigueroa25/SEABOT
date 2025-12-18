from sqlalchemy import Column, Integer, String, Float, ForeignKey, Boolean, Date, DateTime,Text
from sqlalchemy.orm import relationship
from app.database.database import Base


class Message(Base):
    __tablename__ = "messages"

    id = Column(Integer, primary_key=True, index=True)
    conversation_id = Column(Integer, ForeignKey("conversations.id", ondelete="CASCADE"), nullable=False)
    role = Column(String(20))  
    content = Column(Text)  
    response_id = Column(Text)  
    fecha_hora = Column(DateTime)

    # Campos NLP
    score = Column(Float)
    magnitude = Column(Float)
    category = Column(String(20))

    conversation = relationship("Conversation", back_populates="messages")
