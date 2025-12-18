from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from fastapi import status
from app.database.database import get_db
from app.schemas.diaryEntry_schemas import DiaryEntryOut, DiaryEntryCreate, DiaryEntryUpdate,DiaryEntryGet
from app.services import diaryEntry_service

router = APIRouter(prefix="/diaryentries", tags=["Entradas de Diario"])

#@router.post("/", response_model=DiaryEntryOut)
#def create(objecto: DiaryEntryCreate, db: Session = Depends(get_db)):
#    return diaryEntry_service.register(db, objecto)

@router.post("/", status_code=status.HTTP_204_NO_CONTENT)
def create(objecto: DiaryEntryCreate, db: Session = Depends(get_db)):
    diaryEntry_service.register(db, objecto)

@router.get("/", response_model=list[DiaryEntryOut])
def get_objects(db: Session = Depends(get_db)):
    return diaryEntry_service.list_all(db)

@router.get("/{Obj_id}", response_model=DiaryEntryOut)
def get_obj(Obj_id: int, db: Session = Depends(get_db)):
    Objecto = diaryEntry_service.find_by_id(db, Obj_id)
    if not Objecto:
        raise HTTPException(status_code=404, detail="Object not found")
    return Objecto

@router.put("/{Obj_id}", status_code=status.HTTP_204_NO_CONTENT)
def update(Obj_id: int, objecto: DiaryEntryUpdate, db: Session = Depends(get_db)):
    diaryEntry_service.modify(db, Obj_id, objecto)

@router.delete("/{Obj_id}")
def delete(Obj_id: int, db: Session = Depends(get_db)):
    return diaryEntry_service.remove(db, Obj_id)


#Funcionalidades
@router.get("/func/{student_id}", response_model=list[DiaryEntryGet])
def get_entries(student_id: int, db: Session = Depends(get_db)):
    return diaryEntry_service.listarEntries(db, student_id)