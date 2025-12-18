from sqlalchemy.orm import Session
from app.repositories import helpResource_repository
from app.schemas.helpResource_schemas import HelpResourceCreate, HelpResourceUpdate,HelpResourceEnable

def register(db: Session, objecto: HelpResourceCreate):
    return helpResource_repository.create(db, objecto)

def list_all(db: Session):
    return helpResource_repository.get(db)

def find_by_id(db: Session, object_id: int):
    return helpResource_repository.get_by_id(db, object_id)

def modify(db: Session, 
           object_id: int, 
           objecto: HelpResourceUpdate):
    return helpResource_repository.update(db, object_id, objecto)

def remove(db: Session, object_id: int):
    return helpResource_repository.delete(db, object_id)

#Funcionalidades
def modifyEnable(db: Session, 
           object_id: int, 
           objecto: HelpResourceEnable):
    return helpResource_repository.modifyEnable(db, object_id, objecto)

def list_all_enable(db: Session):
    return helpResource_repository.get_enables(db)
