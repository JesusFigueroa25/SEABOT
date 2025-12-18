from fastapi import APIRouter, Depends, HTTPException
from fastapi import status
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.repositories import phqResult_repository
from app.schemas.phqResult_schemas import PhqResultOut, PhqResultCreate, PhqResultUpdate, PhqResultGetPhq
from app.services import phqResult_service

router = APIRouter(prefix="/phqresults", tags=["PHQ Resultados"])

@router.get("/", response_model=list[PhqResultOut])
def get_objects(db: Session = Depends(get_db)):
    return phqResult_service.list_all(db)

@router.get("/{Obj_id}", response_model=PhqResultOut)
def get_obj(Obj_id: int, db: Session = Depends(get_db)):
    Objecto = phqResult_service.find_by_id(db, Obj_id)
    if not Objecto:
        raise HTTPException(status_code=404, detail="Object not found")
    return Objecto

@router.put("/{Obj_id}", status_code=status.HTTP_204_NO_CONTENT)
def update(Obj_id: int, objecto: PhqResultUpdate, db: Session = Depends(get_db)):
    phqResult_service.modify(db, Obj_id, objecto)

@router.delete("/{Obj_id}")
def delete(Obj_id: int, db: Session = Depends(get_db)):
    return phqResult_service.remove(db, Obj_id)

#Funcionalidades
@router.get("/func/{student_id}", response_model=list[PhqResultGetPhq])
def get_Phqs(student_id: int, db: Session = Depends(get_db)):
    return phqResult_service.list_phq(db, student_id)

@router.post("/", status_code=status.HTTP_204_NO_CONTENT)
def create(objecto: PhqResultCreate, db: Session = Depends(get_db)):
    phqResult_service.register(db, objecto)
    
@router.get("/check/{student_id}")
def check_today(student_id: int, db: Session = Depends(get_db)):
    taken = phqResult_repository.has_taken_today(db, student_id)
    return {"taken_today": taken}
