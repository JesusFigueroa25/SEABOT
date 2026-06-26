from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.database.database import Base

class SupportReport(Base):
    __tablename__ = "support_reports"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    report_type = Column(String(50), nullable=False)
    description = Column(Text, nullable=False)
    status = Column(String(30), nullable=False, default="Recibido")
    ruta_foto = Column(Text)
    created_at = Column(DateTime, nullable=False)
    updated_at = Column(DateTime, nullable=True)

    student = relationship("Student", back_populates="reports")
