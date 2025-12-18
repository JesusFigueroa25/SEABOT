from fastapi import HTTPException
from sqlalchemy.orm import Session
from app.models.message_model import Message
from app.models.phqResult_model import PhqResult
from app.models.student_model import Student
from app.models.emotionalRegister_model import EmotionalRegister
from app.repositories import message_repository
from app.repositories import conversation_repository
from app.schemas.message_schemas import MessageCreate, MessageUpdate, MessageInput, MessageOut
from datetime import datetime
from openai import OpenAI
from app.models.conversation_model import Conversation
from app.models.summary_model import Summary

from fastapi import APIRouter
from google.cloud import language_v1

def list_all(db: Session):
    return message_repository.get(db)

def find_by_id(db: Session, object_id: int):
    return message_repository.get_by_id(db, object_id)

def modify(db: Session, 
           object_id: int, 
           objecto: MessageUpdate):
    return message_repository.update(db, object_id, objecto)

def remove(db: Session, object_id: int):
    return message_repository.delete(db, object_id)

#Funcionalidades
def listarMessageByConvID(db: Session, conversation_id: int):
    return message_repository.get_message_by_conversation(db, conversation_id)

def listarLastMessageByConvID(db: Session, conversation_id: int):
    return message_repository.get_last_messages(db, conversation_id)

def count_by_conversation(db: Session, conversation_id: int) -> int:
    return (
        db.query(Message)
        .filter(Message.conversation_id == conversation_id)
        .count()
    )


def ultimosMensajesprueba(db: Session, conversation_id: int):
    # Obtener resumen actual + últimos 2–3 mensajes
    conv = db.query(Conversation).filter_by(id=conversation_id).first()
    resumen = conv.conversation_summary if conv and conv.conversation_summary else ""
    
    ultimos: list[MessageOut] = message_repository.get_last_messages(
        db, conversation_id, limit=3
    )
    
    input_for_response = [
        {"role": "system", "content": f"Resumen previo: {resumen}"},
    ] + [{"role": m.role, "content": m.content} for m in reversed(ultimos)]
    
    return input_for_response

#Crear Mensajes con OpenAI
SYSTEM_PROMPT = (
"""
Eres un acompañante emocional en español (no terapeuta).
Objetivo: brindar apoyo cálido y humano en las conversaciones.

Reglas:
- Nunca diagnostiques ni ofrezcas terapia clínica o recetas médicas.
- Usa un tono cercano, empático y natural (no formal ni robótico).
- Valida emociones y haz preguntas abiertas suaves para invitar a compartir.
- Evita pedir datos personales o prometer confidencialidad total.
- Español latino neutro, claro y sencillo.
- Si el mensaje del usuario contiene expresiones de suicidio o intención de hacerse daño, 
  clasifícalo en una escala de riesgo de 0 a 3 (0 = sin riesgo, 3 = riesgo alto). 
  Si el riesgo es 3, no continúes la conversación: responde de forma breve, empática y 
  ofrece los recursos oficiales en Perú (ejemplo: Línea 113 opción 5 del MINSA, 
  o acudir a la emergencia más cercana).
"""

)
clientGPT = OpenAI(api_key="APIKEY")
MAX_TURNOS_PER_CONVERSATION = 30
 
def create_message(db: Session, obj: MessageInput):
    total = message_repository.count_by_conversation(db, obj.conversation_id) 
    #if total >= MAX_TURNOS_PER_CONVERSATION:
    #    raise HTTPException(
    #        status_code=400,
    #        detail="Se ha alcanzado el límite de 30 mensajes por conversación."
    #    )
    
    # 1. Validaciones y preparación de contexto
    conv = db.query(Conversation).filter_by(id=obj.conversation_id).first()
    resumen = conv.conversation_summary if conv and conv.conversation_summary else ""
    student_id_filter = conv.student_id
     

    #2. CONTEXTO:
    #Contexto PHQ-9
    phq_last = db.query(PhqResult).filter(PhqResult.student_id==student_id_filter).order_by(PhqResult.fecha.desc()).first()
    if phq_last:
        contexto_phq9 = (
            f"Contexto emocional previo del usuario:\n"
            f"- Puntaje PHQ-9 más reciente: {phq_last.total_score}\n"
            f"- Interpretación del estado emocional: {phq_last.interpretation}\n\n"
            f"Usa esta información solo para ajustar el tono y profundidad del acompañamiento emocional. "
            f"No menciones explícitamente que proviene de un test ni des explicaciones clínicas."
        )
    else:
        contexto_phq9 = (
            "No hay resultados previos del PHQ-9 registrados. "
            "Brinda acompañamiento emocional general."
        )
    
    #Contexto Registro Emocional y Alias:
    # Obtener alias del usuario
    student = db.query(Student).filter(Student.id == student_id_filter).first()
    alias = student.alias if student and student.alias else "Usuario"
    emotion_last = db.query(EmotionalRegister).filter(EmotionalRegister.student_id==student_id_filter).order_by(EmotionalRegister.fecha_hora.desc()).first()
    if emotion_last:
        contexto_emocional = (
            f"Último registro emocional del usuario:\n"
            f"- Emoción registrada: {emotion_last.emotion}\n"
            f"- Fecha: {emotion_last.fecha_hora.isoformat()}\n\n"
            f"Utiliza este registro solo para adaptar el tono de acompañamiento. "
            f"No menciones explícitamente que proviene de un formulario."
        )
    else:
        contexto_emocional = (
            "El usuario no tiene registros emocionales previos. "
            "Brinda acompañamiento empático estándar."
        )
        
    contexto_alias = f"El usuario prefiere ser llamado: {alias}. Úsalo para personalizar el acompañamiento."
    

    
    #Contexto de los Últimos 3 mensajes previos
    ultimos: list[MessageOut] = message_repository.get_last_messages(
        db, obj.conversation_id, limit=3
    )
    
    #Contexto del Analisis de sentimiento NLP
    sent_result = analyze_sentiment(obj.content)
    
    sent_score = sent_result["score"]
    sent_magnitude = sent_result["magnitude"]
    sent_category = sent_result["category"]
    
    if sent_category:
        contexto_sentimiento = (
            f"Análisis emocional del mensaje actual del usuario:\n"
            f"- Sentimiento detectado: {sent_category}\n"
            f"- Intensidad emocional (magnitude): {sent_magnitude}\n\n"
            f"Utiliza esta información únicamente para ajustar el tono empático de tu respuesta. "
            f"No menciones explícitamente que proviene de un análisis automático."
        )
    else:
        contexto_sentimiento = (
            "No se detectó un sentimiento claro en el mensaje del usuario. "
            "Brinda acompañamiento emocional estándar."
        )

 

    # Construir contexto para OpenAI
    input_for_response = [
        {"role": "system", "content": SYSTEM_PROMPT},
        # Contexto PHQ9
        {"role": "system", "content": contexto_phq9},
        # Alias del usuario
        {"role": "system", "content": contexto_alias},
        # Último registro emocional
        {"role": "system", "content": contexto_emocional},
        # Sentimiento del mensaje
        {"role": "system", "content": contexto_sentimiento},
        # Resumen previo
        {"role": "assistant", "content": f"Resumen previo: {resumen}"},
    ] + [{"role": m.role, "content": m.content} for m in reversed(ultimos)]


    # Agregar mensaje actual del usuario
    input_for_response.append({"role": "user", "content": obj.content})

    # 3. Llamada a OpenAI (sin conversation_id → memoria la manejas tú)
    response = clientGPT.responses.create(
        model="gpt-4.1-mini",
        input=input_for_response,
        temperature=0.8,
        #max_output_tokens=100,
        metadata={"conversation_id: ": str(obj.openai_id)}
    )

    # Texto de salida del modelo
    output_text = response.output[0].content[0].text
    
    clientGPT.conversations.items.create(
    conversation_id=conv.openai_id,
        items=[
            {
                "type": "message",
                "role": "user",
                "content": [{"type": "input_text", "text": obj.content}]
            },
            {
                "type": "message",
                "role": "assistant",
                "content": [{"type": "output_text", "text": output_text}]
            }
        ]
    )    

    # 5. Guardar mensajes en el BD 
    obj.response_id = response.id
    message_repository.createInput(db,
        MessageCreate(
            conversation_id=obj.conversation_id,
            role="user",
            content=obj.content,
            response_id=obj.response_id,
            fecha_hora=datetime.utcnow(),

            # Sentimiento NLP
            score=sent_score,
            magnitude=sent_magnitude,
            category=sent_category
        )
    )


    bot_msg: MessageOut = message_repository.createOutput(
        db,
        MessageCreate(
            conversation_id=obj.conversation_id,
            role="assistant",
            content=output_text,
            response_id=response.id,
            fecha_hora=datetime.utcnow(),
            # Sentimiento NLP
            score=sent_score,
            magnitude=sent_magnitude,
            category=sent_category
        ),
    )

    # 6. Generar resumen cada 6 mensajes
    if total % 6 == 0:
        bloque = message_repository.get_last_messages(db, obj.conversation_id, limit=6)
        texto_concat = f"Resumen previo: {resumen}\n" + "\n".join(
                [f"{m.role}: {m.content}" for m in reversed(bloque)]
        )
        resumen_resp = clientGPT.responses.create(
            model="gpt-4.1-mini",
            input=[
                {"role": "system", "content": "Resume la conversación de manera breve."},
                {"role": "user", "content": texto_concat}
            ],
            max_output_tokens=170
        )
        resumen_txt = resumen_resp.output[0].content[0].text

        start_id = bloque[0].id
        end_id = bloque[-1].id

        # Guardar resumen en tabla summaries
        db_summary = Summary(
            conversation_id=obj.conversation_id,
            start_message_id=start_id,
            end_message_id=end_id,
            resumen=resumen_txt,
            fecha_hora=datetime.utcnow()
        )
        db.add(db_summary)

        # Actualizar resumen actual de la conversación
        conv.conversation_summary = resumen_txt
        db.commit()

    #return bot_msg
    
    # Preparar JSON del último PHQ-9
    if phq_last:
        phq_json = {
            "score": phq_last.total_score,
            "interpretacion": phq_last.interpretation,
            "fecha": phq_last.fecha.isoformat()
        }
    else:
        phq_json = None
        
    # Preparar JSON del último registro emocional
    if emotion_last:
        emocion_json = {
            "emocion": emotion_last.emotion,
            "fecha": emotion_last.fecha_hora.isoformat()
        }
    else:
        emocion_json = None
    

    return bot_msg


    #return {
    #    "student_id": student_id_filter,
    #    "alias": alias,
    #    "ultimo_emocional": emocion_json,
    #    "assistant_message": bot_msg,
    #    "ultimo_phq9": phq_json
    #}

def analyze_sentiment(text: str):
    clientNLP = language_v1.LanguageServiceClient()

    document = language_v1.Document(
        content=text,
        type_=language_v1.Document.Type.PLAIN_TEXT
    )

    response = clientNLP.analyze_sentiment(request={"document": document})
    sentiment = response.document_sentiment

    score = sentiment.score
    magnitude = sentiment.magnitude

    # Dirección del sentimiento
    if score > 0.25:
        direction = "positive"
    elif score < -0.25:
        direction = "negative"
    elif -0.05 <= score <= 0.05:
        direction = "neutral"
    else:
        direction = "slightly_negative" if score < 0 else "slightly_positive"

    # Intensidad emocional
    if magnitude < 0.2:
        intensity = "very_low"
    elif magnitude < 0.6:
        intensity = "low"
    elif magnitude < 1.5:
        intensity = "medium"
    elif magnitude < 3:
        intensity = "high"
    else:
        intensity = "very_high"

    # Categoría final estilo Google
    if magnitude == 0:
        category = "neutral"
    elif abs(score) < 0.1 and magnitude > 1:
        category = "mixed"
    elif score > 0.25 and magnitude > 1:
        category = "clearly_positive"
    elif score < -0.25 and magnitude > 1:
        category = "clearly_negative"
    else:
        category = direction

    return {
        "score": score,
        "magnitude": magnitude,
        "category": category
    }
