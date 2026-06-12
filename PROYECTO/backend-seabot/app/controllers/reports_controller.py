from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.services import reports_service

router = APIRouter(prefix="/admin/reports", tags=["Reportes Admin"])

# CA1
@router.get("/actividad")
def actividad_semanal(db: Session = Depends(get_db)):
    return reports_service.actividad_semanal(db)

# CA2
@router.get("/emociones")
def emociones(db: Session = Depends(get_db)):
    return reports_service.emociones(db)

# CA3
@router.get("/phq")
def phq_promedio(db: Session = Depends(get_db)):
    return reports_service.phq_promedio(db)

# CA4
@router.get("/usabilidad")
def usabilidad():
    return reports_service.usabilidad()
