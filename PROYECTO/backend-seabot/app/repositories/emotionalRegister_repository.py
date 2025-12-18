from sqlalchemy.orm import Session
from app.models.emotionalRegister_model import EmotionalRegister
from app.schemas.emotionalRegister_schemas import EmotionalRegisterCreate, EmotionalRegisterUpdate
from sqlalchemy import desc, asc
from datetime import date,datetime
from sqlalchemy import func
#Cambiar de clase "schema"

def create(db: Session, objeto: EmotionalRegisterCreate):
    #Colocar todos los atributos correctos
    db_object = EmotionalRegister(
        emotion=objeto.emotion, 
        fecha_hora=objeto.fecha_hora, 
        student_id=objeto.student_id,
    )
    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return db_object

def get(db: Session):
    return db.query(EmotionalRegister).all()

def get_by_id(db: Session, object_id: int):
    return db.query(EmotionalRegister).filter(EmotionalRegister.id == object_id).first()

def update(db: Session, object_id: int, objeto: EmotionalRegisterUpdate):
    db_object = get_by_id(db, object_id)
    if db_object:
    #Colocar todos los atributos correctos
        db_object.emotion = objeto.emotion
        db_object.fecha_hora = objeto.fecha_hora
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
        db.query(EmotionalRegister)
        .filter(EmotionalRegister.student_id == student_id)  
        .order_by(desc(EmotionalRegister.fecha_hora))            
        .limit(8)                                  
        .all()
    )
    

def has_taken_today(db: Session, student_id: int) -> bool:
    today = date.today()
    result = db.query(EmotionalRegister).filter(
        EmotionalRegister.student_id == student_id,
        func.date(EmotionalRegister.fecha_hora) == today
    ).first()
    return result is not None
