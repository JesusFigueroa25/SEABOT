from datetime import date
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.schemas.habit_schema import HabitDailyOut, HabitLogToggleRequest
from app.services import habit_service
from typing import List

router = APIRouter(prefix="/habits", tags=["Habits"])

@router.get("/daily/{student_id}", response_model=List[HabitDailyOut])
def get_daily_habits(
    student_id: int,
    fecha: date | None = Query(None),
    db: Session = Depends(get_db)
):
    return habit_service.get_daily_habits_for_student(db, student_id, fecha)


@router.post("/toggle")
def toggle_habit(
    payload: HabitLogToggleRequest,
    db: Session = Depends(get_db)
):
    habit_service.toggle_habit_for_today(
        db=db,
        student_id=payload.student_id,
        habit_id=payload.habit_id,
        completed=payload.completed
    )
    return {"message": "Progreso de hábito actualizado correctamente"}