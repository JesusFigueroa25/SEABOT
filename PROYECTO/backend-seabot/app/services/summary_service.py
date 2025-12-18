from sqlalchemy.orm import Session
from app.repositories import summary_repository
from app.schemas.summary_schemas import SummaryCreate, SummaryUpdate

def register(db: Session, objecto: SummaryCreate):
    return summary_repository.create(db, objecto)

def list_all(db: Session):
    return summary_repository.get(db)

def find_by_id(db: Session, object_id: int):
    return summary_repository.get_by_id(db, object_id)

def modify(db: Session, 
           object_id: int, 
           objecto: SummaryUpdate):
    return summary_repository.update(db, object_id, objecto)

def remove(db: Session, object_id: int):
    return summary_repository.delete(db, object_id)
