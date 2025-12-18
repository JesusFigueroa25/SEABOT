from sqlalchemy import Column, Integer, String, Float, ForeignKey, Boolean, Date, DateTime
from sqlalchemy.orm import relationship
from app.database.database import Base


class Student(Base):
    __tablename__ = "students"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True)
    alias = Column(String(50), nullable=False)  
    safe_contact = Column(String(10), nullable=False)

     # Relaciones 1:1
    user = relationship("User", back_populates="student")
     # Relaciones 1:N
    phqResults = relationship("PhqResult", back_populates="student")
    diaryEntries = relationship("DiaryEntry", back_populates="student")
    emotionalRegisters = relationship("EmotionalRegister", back_populates="student")
    conversations = relationship("Conversation", back_populates="student")
