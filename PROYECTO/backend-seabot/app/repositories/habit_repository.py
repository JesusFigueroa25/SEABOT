from datetime import date
from sqlalchemy.orm import Session
from app.models.habit_model import Habit
from app.models.habit_log_model import HabitLog

def get_all_habits(db: Session):
    return db.query(Habit).order_by(Habit.id.asc()).all()

def get_habit_log_by_student_habit_fecha(
    db: Session,
    student_id: int,
    habit_id: int,
    fecha: date
):
    return (
        db.query(HabitLog)
        .filter(
            HabitLog.student_id == student_id,
            HabitLog.habit_id == habit_id,
            HabitLog.fecha == fecha
        )
        .first()
    )

def create_habit_log(db: Session, log: HabitLog):
    db.add(log)
    db.commit()
    db.refresh(log)
    return log

def update_habit_log(db: Session, log: HabitLog, completed: bool):
    log.completed = completed
    db.commit()
    db.refresh(log)
    return log

def get_logs_by_student_fecha(db: Session, student_id: int, fecha: date):
    return (
        db.query(HabitLog)
        .filter(
            HabitLog.student_id == student_id,
            HabitLog.fecha == fecha
        )
        .all()
    )