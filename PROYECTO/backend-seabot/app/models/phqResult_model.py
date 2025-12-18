from sqlalchemy import Column, Integer, String, Float, ForeignKey, Boolean, Date, DateTime
from sqlalchemy.orm import relationship
from app.database.database import Base


class PhqResult(Base):
    __tablename__ = "phq_results"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    total_score = Column(Integer, nullable=False)  
    interpretation = Column(String(100), nullable=False)
    fecha = Column(Date)

    student = relationship("Student", back_populates="phqResults")
