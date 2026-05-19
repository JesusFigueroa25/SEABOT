from datetime import date
from sqlalchemy.orm import Session
from app.models.habit_log_model import HabitLog
from app.repositories import habit_repository

def get_daily_habits_for_student(db: Session, student_id: int, fecha: date | None = None):
    fecha = fecha or date.today()

    habits = habit_repository.get_all_habits(db)
    logs = habit_repository.get_logs_by_student_fecha(db, student_id, fecha)

    log_map = {log.habit_id: log for log in logs}

    result = []
    for habit in habits:
        log = log_map.get(habit.id)
        result.append({
            "habit_id": habit.id,
            "name_habit": habit.name_habit,
            "description": habit.description,
            "icon_habit": habit.icon_habit,
            "fecha": fecha,
            "completed": log.completed if log else False
        })

    return result


def toggle_habit_for_today(
    db: Session,
    student_id: int,
    habit_id: int,
    completed: bool,
    fecha: date | None = None
):
    fecha = fecha or date.today()

    log = habit_repository.get_habit_log_by_student_habit_fecha(
        db, student_id, habit_id, fecha
    )

    if not log:
        log = HabitLog(
            habit_id=habit_id,
            student_id=student_id,
            fecha=fecha,
            completed=completed
        )
        return habit_repository.create_habit_log(db, log)

    return habit_repository.update_habit_log(db, log, completed)