from sqlalchemy.orm import Session
from app.models.message_model import Message
from app.schemas.message_schemas import MessageCreate, MessageUpdate, MessageInput, MessageOut
from sqlalchemy import desc, asc
from app.utils.datetime_utils import to_lima_naive

def get(db: Session):
    return db.query(Message).all()

def get_by_id(db: Session, object_id: int):
    return db.query(Message).filter(Message.id == object_id).first()

def update(db: Session, object_id: int, objeto: MessageUpdate):
    db_object = get_by_id(db, object_id)
    if db_object:
        db_object.role = objeto.role
        db_object.content = objeto.content
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
def get_message_by_conversation(db: Session, conversation_id: int):
    return (
        db.query(Message)
        .filter(Message.conversation_id == conversation_id)  
        .order_by(asc(Message.id))    #Message.id.desc()        
        .all()
    )
    
def get_last_messages(db: Session, conversation_id: int, limit: int = 3):
    messages = (
        db.query(Message)
        .filter(Message.conversation_id == conversation_id)
        .order_by(desc(Message.id))
        .limit(limit)
        .all()
    )
    return list(reversed(messages))  # ahora quedan del más viejo al más nuevo


def count_by_conversation(db: Session, conversation_id: int) -> int:
    return (
        db.query(Message)
        .filter(Message.conversation_id == conversation_id)
        .count()
    )

    
    
    
def createOutput(db: Session, objeto: MessageCreate)-> MessageOut:
    db_object = Message(
        role=objeto.role, 
        content=objeto.content, 
        response_id=objeto.response_id, 
        fecha_hora=to_lima_naive(objeto.fecha_hora),
        conversation_id=objeto.conversation_id,
        score=objeto.score,
        magnitude=objeto.magnitude,
        category=objeto.category,
    )
    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return MessageOut.model_validate(db_object)

def createInput(db: Session, objeto: MessageInput):
    print("FECHA RECIBIDA:", objeto.fecha_hora)
    print("TZINFO:", objeto.fecha_hora.tzinfo if objeto.fecha_hora else None)
    print("FECHA LIMA:", to_lima_naive(objeto.fecha_hora))
    db_object = Message(
        role=objeto.role, 
        content=objeto.content, 
        fecha_hora=to_lima_naive(objeto.fecha_hora),
        conversation_id=objeto.conversation_id,
        response_id=objeto.response_id,
        score=objeto.score,
        magnitude=objeto.magnitude,
        category=objeto.category
    )
    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return db_object    