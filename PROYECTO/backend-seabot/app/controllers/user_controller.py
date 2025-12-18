from fastapi import APIRouter, Depends, HTTPException, status
from fastapi import status
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.schemas.user_schema import UserOut, UserCreate, UserUpdate, UserGetEnable, UserEnable,UserGetLogin
from app.schemas.student_schema import StudentOut
from app.services import user_service
from app.services import student_service
from fastapi import Query
from fastapi.security import OAuth2PasswordRequestForm
from app.schemas.user_schema import Token, TokenAdmin, TokenLogin
from app.schemas.user_schema import UserLogin

router = APIRouter(prefix="/users", tags=["Usuarios"])

#@router.post("/", status_code=status.HTTP_204_NO_CONTENT)
#def create(objecto: UserCreate, db: Session = Depends(get_db)):
#    user_service.register(db, objecto)
    
@router.post("/", response_model=UserOut)
def create(objecto: UserCreate, db: Session = Depends(get_db)):
    return user_service.register(db, objecto)

@router.get("/", response_model=list[UserOut])
def get_objects(db: Session = Depends(get_db)):
    return user_service.list_all(db)

@router.get("/{object_id}", response_model=UserOut)
def get_obj(object_id: int, db: Session = Depends(get_db)):
    Objecto = user_service.find_by_id(db, object_id)
    if not Objecto:
        raise HTTPException(status_code=404, 
                            detail="Object not found")
    return Objecto

@router.put("/{object_id}", status_code=status.HTTP_204_NO_CONTENT)
def update(object_id: int, objecto: UserUpdate, db: Session = Depends(get_db)):
    user_service.modify(db, object_id, objecto)

@router.delete("/{object_id}")
def delete(object_id: int, db: Session = Depends(get_db)):
    return user_service.remove(db, object_id)


#Funcionalidades Users
@router.get("/UsersStudent/", response_model=list[UserGetEnable])
def get_Users_Student(db: Session = Depends(get_db)):
    return user_service.getUsersStudent(db)

@router.get("/UsersDetail/{object_id}", response_model=StudentOut)
def get_Users_Detail(object_id: int, db: Session = Depends(get_db)):
    Objecto = student_service.getUsersDetail(db, object_id)
    if not Objecto:
        raise HTTPException(status_code=404, 
                            detail="Object not found")
    return Objecto
 
@router.put("/Enable/{object_id}",status_code=status.HTTP_204_NO_CONTENT)
def updateEnable(object_id: int, objecto: UserEnable, db: Session = Depends(get_db)):
    user_service.modifyEnable(db, object_id, objecto)
    
#Funcionalidades Admin

@router.get("/metricas/")
def get_metricas(db: Session = Depends(get_db)):
    totalUserEnable = user_service.totalUsers(db)
    totalConvEnable = user_service.totalConversationsEnable(db)
    totalRecEnable = user_service.totalRecursosEnable(db)
    return {"usuarios":totalUserEnable,
            "conversaciones":totalConvEnable,
            "recursos":totalRecEnable}    
    
#Login
@router.post("/login/user/", response_model=Token)
def login(user: UserLogin, db: Session = Depends(get_db)):
    return user_service.login_user(db, user.nameuser, user.password)

@router.post("/login/admin/", response_model=TokenAdmin)
def login(user: UserLogin, db: Session = Depends(get_db)):
    return user_service.login_admin(db, user.nameuser, user.password)

# login_unificado
@router.post("/login/", response_model=TokenLogin)
def login(user: UserLogin, db: Session = Depends(get_db)):
    return user_service.login(db, user.nameuser, user.password)

@router.get("/getUserLogin/{object_id}", response_model=UserGetLogin)
def get_obj(object_id: int, db: Session = Depends(get_db)):
    Objecto = user_service.find_by_id(db, object_id)
    if not Objecto:
        raise HTTPException(status_code=404, 
                            detail="Object not found")
    return Objecto



    