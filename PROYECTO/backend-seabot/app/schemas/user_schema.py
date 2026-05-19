from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from typing import List

class UserBase(BaseModel):
    nameuser: str
    enable: bool
    role: str

class UserCreate(UserBase):
    password: str

class UserUpdate(UserBase):
    password: str
    
class UserEnable(BaseModel):
    enable: bool    
 
class UserGetEnable(UserBase):
    id: int   
    
class UserGetLogin(BaseModel):
    id: int
    nameuser: str
    password: str

class UserOut(UserBase):
    id: int
    class Config:
        from_attributes = True
        
        
        


#LOGIN

class UserLogin(BaseModel):
    nameuser: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str
    student_id: int
    id: int
    
class TokenLogin(BaseModel):
    access_token: str
    token_type: str
    id: int
    student_id: int | None = None
    role: str
    
class TokenAdmin(BaseModel):
    access_token: str
    token_type: str
    
#RECUPERAR CONTRASEÑA
class ForgotPasswordRequest(BaseModel):
    correo: EmailStr

class ResetPasswordRequest(BaseModel):
    codigo: str
    new_password: str = Field(..., min_length=4, max_length=100)    