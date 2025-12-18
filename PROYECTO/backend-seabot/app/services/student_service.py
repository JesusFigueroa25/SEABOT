from sqlalchemy.orm import Session
from app.repositories import student_repository
from app.schemas.student_schema import StudentCreate, StudentUpdate

def register(db: Session, objecto: StudentCreate):
    return student_repository.create(db, objecto)

def list_all(db: Session):
    return student_repository.get(db)

def find_by_id(db: Session, object_id: int):
    return student_repository.get_by_id(db, object_id)

def modify(db: Session, 
           object_id: int, 
           objecto: StudentUpdate):
    return student_repository.update(db, object_id, objecto)

def remove(db: Session, object_id: int):
    return student_repository.delete(db, object_id)

#Funcionalidades
def getUsersDetail(db: Session, object_id: int):
    return student_repository.getUsersDetail(db,object_id)