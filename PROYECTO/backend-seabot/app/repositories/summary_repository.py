from sqlalchemy.orm import Session
from app.models.summary_model import Summary
from app.schemas.summary_schemas import SummaryCreate, SummaryUpdate
#Cambiar de clase "schema"

def create(db: Session, objeto: SummaryCreate):
    #Colocar todos los atributos correctos
    db_object = Summary(
        start_message_id=objeto.start_message_id, 
        end_message_id=objeto.end_message_id, 
        resumen=objeto.resumen, 
        fecha_hora=objeto.fecha_hora,
        conversation_id=objeto.conversation_id,
    )
    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return db_object

def get(db: Session):
    return db.query(Summary).all()

def get_by_id(db: Session, object_id: int):
    return db.query(Summary).filter(Summary.id == object_id).first()

def update(db: Session, object_id: int, objeto: SummaryUpdate):
    db_object = get_by_id(db, object_id)
    if db_object:
    #Colocar todos los atributos correctos
        db_object.start_message_id = objeto.start_message_id
        db_object.end_message_id = objeto.end_message_id
        db_object.resumen = objeto.resumen
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
