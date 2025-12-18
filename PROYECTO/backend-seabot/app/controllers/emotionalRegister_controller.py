from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from fastapi import status
from app.database.database import get_db
from app.repositories import emotionalRegister_repository
from app.schemas.emotionalRegister_schemas import EmotionalRegisterOut, EmotionalRegisterCreate, EmotionalRegisterUpdate, EmotionalRegisterGet
from app.services import emotionalRegister_service

router = APIRouter(prefix="/emotionalregisters", tags=["Registros de Emociones"])

@router.post("/", status_code=status.HTTP_204_NO_CONTENT)
def create(objecto: EmotionalRegisterCreate, db: Session = Depends(get_db)):
    emotionalRegister_service.register(db, objecto)

@router.get("/", response_model=list[EmotionalRegisterOut])
def get_objects(db: Session = Depends(get_db)):
    return emotionalRegister_service.list_all(db)

@router.get("/{Obj_id}", response_model=EmotionalRegisterOut)
def get_obj(Obj_id: int, db: Session = Depends(get_db)):
    Objecto = emotionalRegister_service.find_by_id(db, Obj_id)
    if not Objecto:
        raise HTTPException(status_code=404, detail="Object not found")
    return Objecto

@router.put("/{Obj_id}", status_code=status.HTTP_204_NO_CONTENT)
def update(Obj_id: int, objecto: EmotionalRegisterUpdate, db: Session = Depends(get_db)):
    emotionalRegister_service.modify(db, Obj_id, objecto)

@router.delete("/{Obj_id}")
def delete(Obj_id: int, db: Session = Depends(get_db)):
    return emotionalRegister_service.remove(db, Obj_id)


#Funcionalidades
@router.get("/func/{student_id}", response_model=list[EmotionalRegisterGet])
def get_entries(student_id: int, db: Session = Depends(get_db)):
    return emotionalRegister_service.listarEmociones(db, student_id)

@router.get("/check/{student_id}")
def check_today(student_id: int, db: Session = Depends(get_db)):
    taken = emotionalRegister_repository.has_taken_today(db, student_id)
    return {"taken_today": taken}
