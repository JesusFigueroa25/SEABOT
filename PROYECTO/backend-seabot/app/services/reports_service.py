from sqlalchemy.orm import Session
from app.repositories import reports_repository

def actividad_semanal(db: Session):
    return reports_repository.get_actividad_semanal(db)

def emociones(db: Session):
    return reports_repository.get_emociones(db)

def phq_promedio(db: Session):
    return reports_repository.get_phq_promedio(db)

def usabilidad():
    # Datos externos (tu encuesta Google Forms)
    return {
        "empatia": 0.867,
        "coherencia": 0.866,
        "retencion": 0.800,
        "sus": 0.908
    }
