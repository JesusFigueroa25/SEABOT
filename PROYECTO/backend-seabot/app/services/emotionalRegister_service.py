from sqlalchemy.orm import Session
from app.repositories import emotionalRegister_repository
from app.schemas.emotionalRegister_schemas import EmotionalRegisterCreate, EmotionalRegisterUpdate
from fastapi import HTTPException, status
from datetime import date, datetime

def register(db: Session, objecto: EmotionalRegisterCreate):
    return emotionalRegister_repository.create(db, objecto)

def list_all(db: Session):
    return emotionalRegister_repository.get(db)

def find_by_id(db: Session, object_id: int):
    return emotionalRegister_repository.get_by_id(db, object_id)

def modify(db: Session, 
           object_id: int, 
           objecto: EmotionalRegisterUpdate):
    return emotionalRegister_repository.update(db, object_id, objecto)

def remove(db: Session, object_id: int):
    return emotionalRegister_repository.delete(db, object_id)

#Funcionalidades
def listarEmociones(db: Session, student_id: int):
    return emotionalRegister_repository.get_last_8_by_student(db, student_id)

