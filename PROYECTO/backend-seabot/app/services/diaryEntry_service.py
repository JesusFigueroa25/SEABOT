from sqlalchemy.orm import Session
from app.repositories import diaryEntry_repository
from app.schemas.diaryEntry_schemas import DiaryEntryCreate, DiaryEntryUpdate

def register(db: Session, objecto: DiaryEntryCreate):
    return diaryEntry_repository.create(db, objecto)

def list_all(db: Session):
    return diaryEntry_repository.get(db)

def find_by_id(db: Session, object_id: int):
    return diaryEntry_repository.get_by_id(db, object_id)

def modify(db: Session, 
           object_id: int, 
           objecto: DiaryEntryUpdate):
    return diaryEntry_repository.update(db, object_id, objecto)

def remove(db: Session, object_id: int):
    return diaryEntry_repository.delete(db, object_id)

#Funcionalidades
def listarEntries(db: Session, student_id: int):
    return diaryEntry_repository.get_last_8_by_student(db, student_id)