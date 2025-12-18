from sqlalchemy.orm import Session
from app.models.helpResource_model import HelpResource
from app.schemas.helpResource_schemas import HelpResourceCreate, HelpResourceUpdate, HelpResourceEnable
#Cambiar de clase "schema"

def create(db: Session, objeto: HelpResourceCreate):
    #Colocar todos los atributos correctos
    db_object = HelpResource(
        name_resource=objeto.name_resource, 
        enable=objeto.enable, 
        description = objeto.description,
        resource_type = objeto.resource_type,
        url = objeto.url
    )
    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return db_object

def get(db: Session):
    return db.query(HelpResource).all()

def get_enables(db: Session):
    return db.query(HelpResource).filter(HelpResource.enable == True).all()

def get_by_id(db: Session, object_id: int):
    return db.query(HelpResource).filter(HelpResource.id == object_id).first()

def update(db: Session, object_id: int, objeto: HelpResourceUpdate):
    db_object = get_by_id(db, object_id)
    if db_object:
    #Colocar todos los atributos correctos
        db_object.name_resource = objeto.name_resource
        db_object.enable = objeto.enable
        db_object.description = objeto.description
        db_object.resource_type = objeto.resource_type
        db_object.url = objeto.url
        db.commit()
        db.refresh(db_object)
    return db_object

def delete(db: Session, object_id: int):
    db_object = get_by_id(db, object_id)
    if db_object:
        db.delete(db_object)
        db.commit()
    return db_object

#Funcionalidades
def modifyEnable(db: Session, object_id: int, objeto: HelpResourceEnable):
    db_object = get_by_id(db, object_id)
    if db_object:
        db_object.enable = objeto.enable
        db.commit()
        db.refresh(db_object)
    return db_object
