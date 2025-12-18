from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from fastapi import status
from app.database.database import get_db
from app.schemas.conversation_schemas import ConversationOut, ConversationCreate, ConversationUpdate, ConversationGet, ConversationUpdateName, ConversationUpdateCal
from app.schemas.conversation_schemas import ConversationCreateOpenAI, ConversationOpenAIOut
from app.services import conversation_service
from app.repositories import conversation_repository

router = APIRouter(prefix="/conversations", tags=["Conversaciones"])

 
@router.post("/", status_code=status.HTTP_204_NO_CONTENT)
def create(objecto: ConversationCreate, db: Session = Depends(get_db)):
    conversation_service.register(db, objecto)

@router.post("/openai", response_model=ConversationOpenAIOut, status_code=status.HTTP_201_CREATED)
def create_conversation_OpenAI(conv: ConversationCreateOpenAI, db: Session = Depends(get_db)):
    return conversation_service.registerOpenAI(db, conv)    

@router.get("/", response_model=list[ConversationOut])
def get_objects(db: Session = Depends(get_db)):
    return conversation_service.list_all(db)

@router.get("/{Obj_id}", response_model=ConversationOut)
def get_obj(Obj_id: int, db: Session = Depends(get_db)):
    Objecto = conversation_service.find_by_id(db, Obj_id)
    if not Objecto:
        raise HTTPException(status_code=404, detail="Object not found")
    return Objecto

@router.put("/{Obj_id}", status_code=status.HTTP_204_NO_CONTENT)
def update(Obj_id: int, objecto: ConversationUpdate, db: Session = Depends(get_db)):
    conversation_service.modify(db, Obj_id, objecto)

@router.delete("/{Obj_id}")
def delete(Obj_id: int, db: Session = Depends(get_db)):
    return conversation_service.remove(db, Obj_id)

#Funcionalidades
@router.get("/func/{student_id}", response_model=list[ConversationGet])
def get_conversations(student_id: int, db: Session = Depends(get_db)):
    return conversation_service.listarConversations(db, student_id)

@router.put("/updatename/{Obj_id}", status_code=status.HTTP_204_NO_CONTENT)
def update_Name(Obj_id: int, objecto: ConversationUpdateName, db: Session = Depends(get_db)):
    conversation_service.modifyName(db, Obj_id, objecto)
    
@router.put("/updatecalification/{Obj_id}", status_code=status.HTTP_204_NO_CONTENT)
def update_Name(Obj_id: int, objecto: ConversationUpdateCal, db: Session = Depends(get_db)):
    conversation_service.modifyCalification(db, Obj_id, objecto)
    
    
#@router.get("/pruebaa/{conversation_id}")
#def get_student_id_by_conversation_route(conversation_id: int,db: Session = Depends(get_db),):
#    student_id = conversation_repository.get_student_id_by_conversation(db, conversation_id)
#    return {
#        "conversation_id": conversation_id,
#        "student_id": student_id,
#    }
