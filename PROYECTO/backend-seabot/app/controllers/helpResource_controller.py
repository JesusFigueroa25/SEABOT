from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from fastapi import status
from app.database.database import get_db
from app.schemas.helpResource_schemas import HelpResourceOut, HelpResourceCreate, HelpResourceUpdate,  HelpResourceEnable
from app.services import helpResource_service

router = APIRouter(prefix="/helpresources", tags=["Recursos de Ayuda"])

#@router.post("/", response_model=HelpResourceOut)
#def create(objecto: HelpResourceCreate, db: Session = Depends(get_db)):
#    return helpResource_service.register(db, objecto)

@router.post("/", status_code=status.HTTP_204_NO_CONTENT)
def create(objecto: HelpResourceCreate, db: Session = Depends(get_db)):
    helpResource_service.register(db, objecto)

@router.get("/", response_model=list[HelpResourceOut])
def get_objects(db: Session = Depends(get_db)):
    return helpResource_service.list_all(db)

@router.get("/{Obj_id}", response_model=HelpResourceOut)
def get_obj(Obj_id: int, db: Session = Depends(get_db)):
    Objecto = helpResource_service.find_by_id(db, Obj_id)
    if not Objecto:
        raise HTTPException(status_code=404, detail="Object not found")
    return Objecto

@router.put("/{Obj_id}",  status_code=status.HTTP_204_NO_CONTENT)
def update(Obj_id: int, objecto: HelpResourceUpdate, db: Session = Depends(get_db)):
    helpResource_service.modify(db, Obj_id, objecto)

@router.delete("/{Obj_id}")
def delete(Obj_id: int, db: Session = Depends(get_db)):
    return helpResource_service.remove(db, Obj_id)

#Funcionalidades
@router.put("/ModifyEnable/{Obj_id}", status_code=status.HTTP_204_NO_CONTENT)
def modifyEnable(Obj_id: int, objecto: HelpResourceEnable, db: Session = Depends(get_db)):
    helpResource_service.modifyEnable(db, Obj_id, objecto)
    
@router.get("/func/enables", response_model=list[HelpResourceOut])
def get_objects_enables(db: Session = Depends(get_db)):
    return helpResource_service.list_all_enable(db)    