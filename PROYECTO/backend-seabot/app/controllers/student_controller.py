from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from fastapi import status
from app.database.database import get_db
from app.models.student_model import Student
from app.schemas.student_schema import StudentOut, StudentCreate, StudentUpdate, StudentGet
from app.services import student_service
from sqlalchemy import func


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

@router.get("/by-user/{user_id}", response_model=StudentGet)
def get_by_user_id(user_id: int, db: Session = Depends(get_db)):
    objecto = student_service.find_by_user_id(db, user_id)
    if not objecto:
        raise HTTPException(status_code=404, detail="Student not found for user")
    return objecto

@router.put("/{Obj_id}", status_code=status.HTTP_204_NO_CONTENT)
def update(Obj_id: int, objecto: StudentUpdate, db: Session = Depends(get_db)):
    student_service.modify(db, Obj_id, objecto)

@router.delete("/{Obj_id}")
def delete(Obj_id: int, db: Session = Depends(get_db)):
    return student_service.remove(db, Obj_id)

#Funcionalidad
@router.get("/exists/correo/{correo}")
def exists_correo(correo: str, db: Session = Depends(get_db)):
    exists = student_service.exists_by_correo(db, correo)
    return {"exists": exists}