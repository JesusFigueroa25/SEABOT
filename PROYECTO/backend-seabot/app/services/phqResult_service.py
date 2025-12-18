from sqlalchemy.orm import Session
from app.repositories import phqResult_repository
from app.schemas.phqResult_schemas import PhqResultCreate, PhqResultUpdate
from fastapi import HTTPException, status
from datetime import date

def register(db: Session, objecto: PhqResultCreate):
    return phqResult_repository.create(db, objecto)

def list_all(db: Session):
    return phqResult_repository.get(db)

def find_by_id(db: Session, object_id: int):
    return phqResult_repository.get_by_id(db, object_id)

def modify(db: Session, 
           object_id: int, 
           objecto: PhqResultUpdate):
    return phqResult_repository.update(db, object_id, objecto)

def remove(db: Session, object_id: int):
    return phqResult_repository.delete(db, object_id)

#Funcionalidades
def list_phq(db: Session, student_id: int):
    return phqResult_repository.get_last_8_by_student(db, student_id)

def registerPHQ(db: Session, objecto: PhqResultCreate):
    # 🔹 Verificar si ya existe un test hoy
    if phqResult_repository.has_taken_today(db, objecto.student_id):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ya realizaste el test PHQ-9 hoy. Intenta nuevamente mañana."
        )
    
    # 🔹 Si no existe, crear nuevo registro
    return phqResult_repository.create(db, objecto)
