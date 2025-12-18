from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, ForeignKey, Boolean, Date, DateTime
from sqlalchemy.orm import relationship
from app.database.database import Base


class EmotionalRegister(Base):
    __tablename__ = "emotional_registers"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    emotion = Column(String(30), nullable=False)  
    fecha_hora = Column(DateTime)

    student = relationship("Student", back_populates="emotionalRegisters")
