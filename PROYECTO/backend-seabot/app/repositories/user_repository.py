from sqlalchemy.orm import Session
#from sqlalchemy.orm import Session,asc, desc
from app.models.student_model import Student
from app.models.user_model import User
from app.models.conversation_model import Conversation
from app.models.helpResource_model import HelpResource
from app.schemas.user_schema import UserCreate, UserUpdate, UserEnable

#Cambiar de clase "schema"

def create(db: Session, objeto: UserCreate):
    #Colocar todos los atributos correctos
    db_object = User(
        nameuser=objeto.nameuser,
        password=objeto.password,
        enable=objeto.enable,
        role=objeto.role,
    )
    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return db_object

def get(db: Session):
    return db.query(User).all()

def get_by_id(db: Session, object_id: int):
    return db.query(User).filter(User.id == object_id).first()

def update(db: Session, object_id: int, objeto: UserUpdate):
    db_object = get_by_id(db, object_id)
    if db_object:
    #Colocar todos los atributos correctos
        db_object.nameuser = objeto.nameuser
        db_object.password = objeto.password
        db_object.enable = objeto.enable
        db_object.role = objeto.role
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
def getUsersStudent(db: Session):
    return db.query(User).filter(User.role=="user").all()

def updateEnable(db: Session, object_id: int, objeto: UserEnable):
    db_object = get_by_id(db, object_id)
    if db_object:
        db_object.enable = objeto.enable
        db.commit()
        db.refresh(db_object)
        
def getLastUserID(db: Session) -> int | None:
    result = (
        db.query(User)
        .filter(User.role == "user")
        .order_by(User.id.desc())
        .first()
    )
    return result.id if result else None


#Metricas
def TotalUsers(db: Session):
    return db.query(User).filter(User.enable==True, User.role=="user").count()
def TotalConversationsEnable(db: Session):
   return db.query(Conversation).filter(Conversation.enable == True).count()
def totalRecursosEnable(db: Session):
    return db.query(HelpResource).filter(HelpResource.enable==True).count()   


#Login
def get_by_name_user(db: Session, nameuser: str):
    return db.query(User).filter(User.nameuser == nameuser).first()

def get_by_name_admin(db: Session, nameuser: str):
    return db.query(User).filter(User.nameuser == nameuser, User.role=="admin" ).first()

def get_by_name(db: Session, nameuser: str):
    return db.query(User).filter(User.nameuser == nameuser).first()

def getStudentID(db: Session, user: User) -> int | None:
    result = db.query(Student.id).filter(Student.user_id == user.id).first()
    return result[0] if result else None
