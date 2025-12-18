from sqlalchemy.orm import Session
from app.models.diaryEntry_model import DiaryEntry
from app.schemas.diaryEntry_schemas import DiaryEntryCreate, DiaryEntryUpdate
from sqlalchemy import desc, asc
#Cambiar de clase "schema"

def create(db: Session, objeto: DiaryEntryCreate):
    #Colocar todos los atributos correctos
    db_object = DiaryEntry(
        entry=objeto.entry, 
        fecha_hora=objeto.fecha_hora, 
        student_id=objeto.student_id,
    )
    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return db_object

def get(db: Session):
    return db.query(DiaryEntry).all()

def get_by_id(db: Session, object_id: int):
    return db.query(DiaryEntry).filter(DiaryEntry.id == object_id).first()

def update(db: Session, object_id: int, objeto: DiaryEntryUpdate):
    db_object = get_by_id(db, object_id)
    if db_object:
    #Colocar todos los atributos correctos
        db_object.entry = objeto.entry
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
        db.query(DiaryEntry)
        .filter(DiaryEntry.student_id == student_id)  
        .order_by(desc(DiaryEntry.fecha_hora))            
        .limit(8)                                  
        .all()
    )
