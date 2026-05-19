from sqlalchemy import Column, Integer, Boolean, Date, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database.database import Base

class HabitLog(Base):
    __tablename__ = "habit_logs"

    id = Column(Integer, primary_key=True, index=True)
    habit_id = Column(Integer, ForeignKey("habits.id", ondelete="CASCADE"), nullable=False)
    student_id = Column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    fecha = Column(Date, nullable=False, server_default=func.current_date())
    completed = Column(Boolean, default=False, nullable=False)

    __table_args__ = (
        UniqueConstraint("habit_id", "student_id", "fecha", name="uq_habit_student_fecha"),
    )

    habit = relationship("Habit")