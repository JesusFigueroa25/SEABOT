from sqlalchemy.orm import Session
from app.models.phqResult_model import PhqResult
from app.schemas.phqResult_schemas import PhqResultCreate, PhqResultUpdate
from sqlalchemy import desc, asc
from datetime import date

def create(db: Session, objeto: PhqResultCreate):
    #Colocar todos los atributos correctos
    db_object = PhqResult(
        total_score=objeto.total_score, 
        interpretation=objeto.interpretation, 
        fecha=objeto.fecha, 
        student_id=objeto.student_id,
    )
    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return db_object

def get(db: Session):
    return db.query(PhqResult).all()

def get_by_id(db: Session, object_id: int):
    return db.query(PhqResult).filter(PhqResult.id == object_id).first()

def update(db: Session, object_id: int, objeto: PhqResultUpdate):
    db_object = get_by_id(db, object_id)
    if db_object:
    #Colocar todos los atributos correctos
        db_object.total_score = objeto.total_score
        db_object.interpretation = objeto.interpretation
        db_object.fecha = objeto.fecha
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

def get_last_8_by_student(db: Session, student_id: int):
    return (
        db.query(PhqResult)
        .filter(PhqResult.student_id == student_id)  
        .order_by(desc(PhqResult.id))        
        .limit(8)    
        .all()
    )

def has_taken_today(db: Session, student_id: int) -> bool:
    today = date.today()
    result = db.query(PhqResult).filter(
        PhqResult.student_id == student_id,
        PhqResult.fecha == today
    ).first()
    return result is not None
