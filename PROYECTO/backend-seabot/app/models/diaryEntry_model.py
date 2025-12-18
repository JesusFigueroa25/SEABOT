from sqlalchemy import Column, Integer, String, Float, ForeignKey, Boolean, Date, DateTime,Text
from sqlalchemy.orm import relationship
from app.database.database import Base


class DiaryEntry(Base):
    __tablename__ = "diary_entries"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    entry = Column(Text, nullable=False)  
    fecha_hora = Column(DateTime)

    student = relationship("Student", back_populates="diaryEntries")
