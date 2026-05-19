from sqlalchemy import Column, Integer, String, Text
from app.database.database import Base

class Habit(Base):
    __tablename__ = "habits"

    id = Column(Integer, primary_key=True, index=True)
    name_habit = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    icon_habit = Column(String(50), nullable=True)