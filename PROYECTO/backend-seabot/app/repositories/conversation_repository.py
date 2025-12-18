from fastapi import HTTPException
from sqlalchemy.orm import Session
from app.models.conversation_model import Conversation
from app.schemas.conversation_schemas import ConversationCreate, ConversationUpdate, ConversationUpdateName, ConversationUpdateCal
from sqlalchemy import desc, asc

#Cambiar de clase "schema"


def get(db: Session):
    return db.query(Conversation).all()

def get_by_id(db: Session, object_id: int):
    return db.query(Conversation).filter(Conversation.id == object_id).first()

def update(db: Session, object_id: int, objeto: ConversationUpdate):
    db_object = get_by_id(db, object_id)
    if db_object:
    #Colocar todos los atributos correctos
        db_object.openai_id = objeto.openai_id
        db_object.name_conversation = objeto.name_conversation
        db_object.qualification = objeto.qualification
        db_object.fecha_inicio = objeto.fecha_inicio
        db_object.enable = objeto.enable
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
def get_conv_by_student(db: Session, studentID: int):
    return (
        db.query(Conversation)
        .filter(Conversation.student_id == studentID)  
        .order_by(desc(Conversation.fecha_inicio))            
        .all()
    )

def update_Name(db: Session, object_id: int, objeto: ConversationUpdateName):
    db_object = get_by_id(db, object_id)
    if db_object:
        db_object.name_conversation = objeto.name_conversation
        db.commit()
        db.refresh(db_object)
    return db_object

def modifyCalification(db: Session, object_id: int, objeto: ConversationUpdateCal):
    db_object = get_by_id(db, object_id)
    if db_object:
        db_object.qualification = objeto.qualification
        db.commit()
        db.refresh(db_object)
    return db_object    


def get_student_id_by_conversation(db: Session, conversation_id: int) -> int:
    conv = (
        db.query(Conversation)
        .filter(Conversation.id == conversation_id)
        .first()
    )
    return conv.student_id


#Crear Conversacion de OpenAI

def count_active_by_student(db: Session, student_id: int) -> int:
    return db.query(Conversation).filter(
        Conversation.student_id == student_id,
        Conversation.enable == True
    ).count()

def create(db: Session, objeto: ConversationCreate):
    #Colocar todos los atributos correctos
    db_object = Conversation(
        openai_id=objeto.openai_id, 
        name_conversation=objeto.name_conversation, 
        qualification=objeto.qualification, 
        fecha_inicio=objeto.fecha_inicio, 
        enable=objeto.enable, 
        student_id=objeto.student_id,
    )
    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return db_object
