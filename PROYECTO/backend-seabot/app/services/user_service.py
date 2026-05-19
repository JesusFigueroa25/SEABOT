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
 
 
#LOGIN
def login(db: Session, username: str, password: str):
    username_clean = username.strip()

    db_user = user_repository.get_by_name(db, username_clean)

    if not db_user:
        raise HTTPException(
            status_code=404,
            detail="El usuario no existe"
        )

    if not db_user.enable:
        raise HTTPException(
            status_code=403,
            detail="Usuario desactivado"
        )

    if not auth.verify_password(password, db_user.password):
        raise HTTPException(
            status_code=401,
            detail="Contraseña incorrecta"
        )

    student_id = None
    if db_user.role == "user":
        student_id = user_repository.getStudentID(db, db_user)

    access_token = auth.create_access_token({
        "sub": db_user.nameuser,
        "role": db_user.role
    })

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "id": db_user.id,
        "student_id": student_id,
        "role": db_user.role
    }