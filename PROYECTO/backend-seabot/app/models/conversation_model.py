from sqlalchemy import Column, Integer, String, Float, ForeignKey, Boolean, Date, DateTime,Text, text
from sqlalchemy.orm import relationship
from app.database.database import Base


class Conversation(Base):
    __tablename__ = "conversations"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    openai_id = Column(Text)  
    name_conversation = Column(String(100))
    qualification = Column(Integer)
    fecha_inicio = Column(DateTime, nullable=False)
    enable = Column(Boolean, nullable=False, server_default=text("true"), default=True)
    conversation_summary = Column(Text)  


     # Relaciones foranea
    student = relationship("Student", back_populates="conversations")
     # Relaciones 1:N
    messages = relationship("Message", back_populates="conversation")
    sumaries = relationship("Summary", back_populates="conversation")
