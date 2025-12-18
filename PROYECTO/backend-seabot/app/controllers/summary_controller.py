from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from fastapi import status
from app.database.database import get_db
from app.schemas.summary_schemas import SummaryOut, SummaryCreate, SummaryUpdate
from app.services import summary_service

router = APIRouter(prefix="/summaries", tags=["Resumenes"])

@router.post("/", status_code=status.HTTP_204_NO_CONTENT)
def create(objecto: SummaryCreate, db: Session = Depends(get_db)):
    summary_service.register(db, objecto)

@router.get("/", response_model=list[SummaryOut])
def get_objects(db: Session = Depends(get_db)):
    return summary_service.list_all(db)

@router.get("/{Obj_id}", response_model=SummaryOut)
def get_obj(Obj_id: int, db: Session = Depends(get_db)):
    Objecto = summary_service.find_by_id(db, Obj_id)
    if not Objecto:
        raise HTTPException(status_code=404, detail="Object not found")
    return Objecto

@router.put("/{Obj_id}", status_code=status.HTTP_204_NO_CONTENT)
def update(Obj_id: int, objecto: SummaryUpdate, db: Session = Depends(get_db)):
    summary_service.modify(db, Obj_id, objecto)

@router.delete("/{Obj_id}")
def delete(Obj_id: int, db: Session = Depends(get_db)):
    return summary_service.remove(db, Obj_id)