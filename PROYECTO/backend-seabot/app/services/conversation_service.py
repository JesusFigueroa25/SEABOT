from datetime import datetime
from fastapi import HTTPException, status
from sqlalchemy import text
from openai import OpenAI
from sqlalchemy.orm import Session
from app.repositories import conversation_repository
from app.schemas.conversation_schemas import ConversationCreate, ConversationUpdate, ConversationUpdateName, ConversationUpdateCal, ConversationCreateOpenAI
from app.models.student_model import Student 

def register(db: Session, objecto: ConversationCreate):
    return conversation_repository.create(db, objecto)

def list_all(db: Session):
    return conversation_repository.get(db)

def find_by_id(db: Session, object_id: int):
    return conversation_repository.get_by_id(db, object_id)

def modify(db: Session, 
           object_id: int, 
           objecto: ConversationUpdate):
    return conversation_repository.update(db, object_id, objecto)

def remove(db: Session, object_id: int):
    return conversation_repository.delete(db, object_id)

#Funcionalidades
def listarConversations(db: Session, student_id: int):
    return conversation_repository.get_conv_by_student(db, student_id)

def modifyName(db: Session, 
           object_id: int, 
           objecto: ConversationUpdateName):
    return conversation_repository.update_Name(db, object_id, objecto)

def modifyCalification(db: Session, 
           object_id: int, 
           objecto: ConversationUpdateCal):
    return conversation_repository.modifyCalification(db, object_id, objecto)

#Crear Conversacion de OpenAI

client = OpenAI(api_key="APIKEY")
MAX_ACTIVE_CONVS = 3

def registerOpenAI(db: Session, objeto: ConversationCreateOpenAI) :  
    # (opcional) Verifica que el student exista
    student = db.query(Student).filter(Student.id == objeto.student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado")

    # (Recomendado) Evitar carreras con un lock por estudiante
    db.execute(text("SELECT pg_advisory_xact_lock(:k)"), {"k": objeto.student_id})

    # 1) Límite de conversaciones activas
    active = conversation_repository.count_active_by_student(db, objeto.student_id)
    if active >= MAX_ACTIVE_CONVS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Límite de conversaciones alcanzado ({MAX_ACTIVE_CONVS})."
        )

    # 2) Crear conversación en OpenAI
    openai_conv = client.conversations.create(
        metadata={"student_id": str(objeto.student_id)},
    )
    # 3) Persistir en BD
    data = ConversationCreate(
        openai_id=openai_conv.id,
        name_conversation="Conversación nueva",
        qualification=0,
        fecha_inicio=datetime.utcnow(),
        enable=True,
        student_id=objeto.student_id,
    )
    return conversation_repository.create(db, data)
