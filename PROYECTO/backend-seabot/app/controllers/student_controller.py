from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from fastapi import status
from app.database.database import get_db
from app.schemas.student_schema import StudentOut, StudentCreate, StudentUpdate, StudentGet
from app.services import student_service

router = APIRouter(prefix="/students", tags=["Estudiantes"])

@router.post("/", response_model=StudentGet)
def create(objecto: StudentCreate, db: Session = Depends(get_db)):
    return student_service.register(db, objecto)

@router.get("/", response_model=list[StudentOut])
def get_objects(db: Session = Depends(get_db)):
    return student_service.list_all(db)

@router.get("/{Obj_id}", response_model=StudentGet)
def get_obj(Obj_id: int, db: Session = Depends(get_db)):
    Objecto = student_service.find_by_id(db, Obj_id)
    if not Objecto:
        raise HTTPException(status_code=404, detail="Object not found")
    return Objecto

@router.put("/{Obj_id}", status_code=status.HTTP_204_NO_CONTENT)
def update(Obj_id: int, objecto: StudentUpdate, db: Session = Depends(get_db)):
    student_service.modify(db, Obj_id, objecto)

@router.delete("/{Obj_id}")
def delete(Obj_id: int, db: Session = Depends(get_db)):
    return student_service.remove(db, Obj_id)
