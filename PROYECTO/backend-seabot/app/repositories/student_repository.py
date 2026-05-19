from sqlalchemy.orm import Session
from sqlalchemy import func
from fastapi import HTTPException
from app.models.student_model import Student
from app.schemas.student_schema import StudentCreate, StudentUpdate
#Cambiar de clase "schema"

def create(db: Session, objeto: StudentCreate):
    correo_clean = objeto.correo.strip().lower()

    existing_student = db.query(Student).filter(
        func.lower(Student.correo) == correo_clean
    ).first()

    if existing_student:
        raise HTTPException(
            status_code=409,
            detail="El correo ya está registrado"
        )

    db_object = Student(
        alias=objeto.alias.strip(),
        safe_contact=objeto.safe_contact,
        correo=correo_clean,
        user_id=objeto.user_id,
    )

    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return db_object

def get(db: Session):
    return db.query(Student).all()

def get_by_id(db: Session, object_id: int):
    return db.query(Student).filter(Student.id == object_id).first()

def update(db: Session, object_id: int, objeto: StudentUpdate):
    db_object = get_by_id(db, object_id)
    if db_object:
    #Colocar todos los atributos correctos
        db_object.alias = objeto.alias
        db_object.safe_contact = objeto.safe_contact
        db_object.correo = objeto.correo
        db.commit()
        db.refresh(db_object)
    return db_object

def delete(db: Session, object_id: int):
    db_object = get_by_id(db, object_id)
    if db_object:
        db.delete(db_object)
        db.commit()
    return db_object

#Funcionalidades
def getUsersDetail(db: Session, user_id: int):
    return db.query(Student).filter(Student.user_id == user_id).first()

def exists_by_correo(db: Session, correo: str) -> bool:
    correo_clean = correo.strip().lower()

    existing_student = db.query(Student).filter(
        func.lower(Student.correo) == correo_clean
    ).first()

    return existing_student is not None