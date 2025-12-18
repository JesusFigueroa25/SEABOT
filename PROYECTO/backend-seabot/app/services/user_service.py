from sqlalchemy.orm import Session
from datetime import timedelta
from app.security import auth
from fastapi import HTTPException, status
from app.repositories import user_repository
from app.schemas.user_schema import UserCreate, UserEnable, UserUpdate

def register(db: Session, objecto: UserCreate):
    return user_repository.create(db, objecto)

def list_all(db: Session):
    return user_repository.get(db)

def find_by_id(db: Session, object_id: int):
    return user_repository.get_by_id(db, object_id)

def modify(db: Session,
           object_id: int, 
           objecto: UserUpdate):
    return user_repository.update(db, object_id, objecto)

def remove(db: Session, object_id: int):
    return user_repository.delete(db, object_id)

#Funcionalidades

def getUsersStudent(db: Session):
    return user_repository.getUsersStudent(db)

def modifyEnable(db: Session,
           object_id: int, 
           objecto: UserEnable):
    user_repository.updateEnable(db, object_id, objecto)
    
#Metricas    
def totalUsers(db: Session):
    return user_repository.TotalUsers(db)
def totalConversationsEnable(db: Session):
    return user_repository.TotalConversationsEnable(db)
def totalRecursosEnable(db: Session):
    return user_repository.totalRecursosEnable(db)
 
 
 #Login

#LOGINS
def login_user(db: Session, username: str, password: str):
    db_user = user_repository.get_by_name_user(db, username)
    student_id = user_repository.getStudentID(db, db_user)
    if not db_user or db_user.role != "user" or not db_user.enable:
        raise HTTPException(status_code=401, detail="Usuario no autorizado")

    if password != db_user.password:  
        raise HTTPException(status_code=401, detail="Credenciales inválidas")

    access_token = auth.create_access_token({"sub": db_user.nameuser})
    return {"access_token": access_token, "token_type": "bearer", "student_id":student_id, "id":db_user.id}



def login_admin(db: Session, username: str, password: str):
    db_admin = user_repository.get_by_name_admin(db, username)
    if not db_admin or db_admin.role != "admin" or not db_admin.enable:
        raise HTTPException(status_code=401, detail="Admin no autorizado")

    if password != db_admin.password:  
        raise HTTPException(status_code=401, detail="Credenciales inválidas")
    
    access_token = auth.create_access_token({"sub": db_admin.nameuser})
    return {"access_token": access_token, "token_type": "bearer"}

def login(db: Session, username: str, password: str):
    db_user = user_repository.get_by_name(db, username)

    if not db_user or not db_user.enable:
        raise HTTPException(status_code=401, detail="Usuario no autorizado")

    # 🔐 Validar contraseña
    if password != db_user.password:  
        raise HTTPException(status_code=401, detail="Credenciales inválidas")

    # 🧠 Si es un estudiante -> buscar id_student
    student_id = None
    if db_user.role == "user":
        student_id = user_repository.getStudentID(db, db_user)

    # 🎟️ Generar token de acceso
    access_token = auth.create_access_token({"sub": db_user.nameuser, "role": db_user.role})

    # 🧩 Respuesta según tipo
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "id": db_user.id,
        "student_id": student_id,
        "role": db_user.role
    }