from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from fastapi import status
from app.database.database import get_db
from app.models.message_model import Message
from app.schemas.message_schemas import MessageOut, MessageCreate, MessageOutDebug, MessageUpdate, MessageInput
from app.services import message_service
from typing import Any


from app.services.message_service import analyze_sentiment
from fastapi import APIRouter
from google.cloud import language_v1

router = APIRouter(prefix="/messages", tags=["Mensajes"])

@router.get("/", response_model=list[MessageOut])
def get_objects(db: Session = Depends(get_db)):
    return message_service.list_all(db)

@router.get("/{Obj_id}", response_model=MessageOut)
def get_obj(Obj_id: int, db: Session = Depends(get_db)):
    Objecto = message_service.find_by_id(db, Obj_id)
    if not Objecto:
        raise HTTPException(status_code=404, detail="Object not found")
    return Objecto

@router.put("/{Obj_id}", status_code=status.HTTP_204_NO_CONTENT)
def update(Obj_id: int, objecto: MessageUpdate, db: Session = Depends(get_db)):
    message_service.modify(db, Obj_id, objecto)

@router.delete("/{Obj_id}")
def delete(Obj_id: int, db: Session = Depends(get_db)):
    return message_service.remove(db, Obj_id) 

#Funcionalidades

@router.get("/GetMessages/{conversation_id}", response_model=list[MessageOut])
def get_messages(conversation_id: int, db: Session = Depends(get_db)):
    return message_service.listarMessageByConvID(db, conversation_id)

@router.post("/createMessages", response_model=MessageOut, status_code=status.HTTP_201_CREATED)
def create(objecto: MessageInput, db: Session = Depends(get_db)):
    return message_service.create_message(db, objecto)

@router.get("/GetLast3Messages/{conversation_id}", response_model=list[MessageOut])
def get_messages(conversation_id: int, db: Session = Depends(get_db)):
    return message_service.listarLastMessageByConvID(db, conversation_id)

@router.get("/prueba/{conversation_id}", response_model=list[dict[str, Any]])
def get_messages(conversation_id: int, db: Session = Depends(get_db)):
    return message_service.ultimosMensajesprueba(db, conversation_id)

@router.get("/contar/{conversation_id}")
def get_messages(conversation_id: int, db: Session = Depends(get_db)):
    return message_service.count_by_conversation(db, conversation_id)

#Analis de sentimiento

@router.post("/test-sentiment")
def test_sentiment(text: str):
    client = language_v1.LanguageServiceClient()

    document = language_v1.Document(
        content=text,
        type_=language_v1.Document.Type.PLAIN_TEXT
    )

    response = client.analyze_sentiment(request={"document": document})

    document_sentiment = response.document_sentiment

    # Sentimientos de oraciones individuales
    sentences = []
    for sentence in response.sentences:
        sentences.append({
            "text": sentence.text.content,
            "score": sentence.sentiment.score,
            "magnitude": sentence.sentiment.magnitude
        })


        # Dirección emocional (score)
    if document_sentiment.score > 0.25:
        direction = "positive"
    elif document_sentiment.score < -0.25:
        direction = "negative"
    elif -0.05 <= document_sentiment.score <= 0.05:
        direction = "neutral"
    else:
        direction = "slightly_negative" if document_sentiment.score < 0 else "slightly_positive"

    # Intensidad emocional (magnitude)
    if document_sentiment.magnitude < 0.2:
        intensity = "very_low"
    elif document_sentiment.magnitude < 0.6:
        intensity = "low"
    elif document_sentiment.magnitude < 1.5:
        intensity = "medium"
    elif document_sentiment.magnitude < 3:
        intensity = "high"
    else:
        intensity = "very_high"

    # Categoría Google-like (positivo/claro, negativo/claro, neutral o mixto)
    if document_sentiment.magnitude == 0:
        category = "neutral"
    elif abs(document_sentiment.score) < 0.1 and document_sentiment.magnitude > 1:
        category = "mixed"
    elif document_sentiment.score > 0.25 and document_sentiment.magnitude > 1:
        category = "clearly_positive"
    elif document_sentiment.score < -0.25 and document_sentiment.magnitude > 1:
        category = "clearly_negative"
    else:
        category = direction

    return {
        "document": {
            "score": document_sentiment.score,
            "magnitude": document_sentiment.magnitude
        },
        "sentences": sentences,
        "category": category
    }
    
#ENDPOINT para actualizar SOLO esos mensajes
@router.post("/fixSentimentsByConversation")
def fix_sentiments_by_conversation(conversations: list[int], db: Session = Depends(get_db)):
    updated = []

    # 1. Filtrar mensajes sin score y dentro del listado de conversaciones
    messages = (
        db.query(Message)
        .filter(
            Message.conversation_id.in_(conversations),
            Message.score == None
        )
        .all()
    )

    for msg in messages:
        result = analyze_sentiment(msg.content)

        msg.score = result["score"]
        msg.magnitude = result["magnitude"]
        msg.category = result["category"]

        updated.append({
            "id": msg.id,
            "conversation_id": msg.conversation_id,
            "score": msg.score,
            "magnitude": msg.magnitude,
            "category": msg.category
        })

    db.commit()

    return {
        "total_actualizados": len(updated),
        "mensajes": updated
    }
    
    