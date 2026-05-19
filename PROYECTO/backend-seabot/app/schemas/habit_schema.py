from datetime import date
from pydantic import BaseModel
from typing import Optional

class HabitBase(BaseModel):
    name_habit: str
    description: Optional[str] = None
    icon_habit: Optional[str] = None

class HabitOut(HabitBase):
    id: int

    class Config:
        from_attributes = True


class HabitDailyOut(BaseModel):
    habit_id: int
    name_habit: str
    description: Optional[str] = None
    icon_habit: Optional[str] = None
    fecha: date
    completed: bool

    class Config:
        from_attributes = True


class HabitLogToggleRequest(BaseModel):
    habit_id: int
    student_id: int
    completed: bool