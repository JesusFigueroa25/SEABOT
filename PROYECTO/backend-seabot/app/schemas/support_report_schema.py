from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from fastapi import Form

class SupportReportBase(BaseModel):
    report_type: Optional[str] = None
    description: Optional[str] = None
    status: Optional[str] = None
    ruta_foto: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class SupportReportCreateSchema(BaseModel):
    student_id: int
    report_type: Optional[str] = None
    description: Optional[str] = None
    status: Optional[str] = None
    ruta_foto: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    
class SupportReportCreate(BaseModel):
    student_id: int
    report_type: str
    description: str
    ruta_foto: Optional[str] = None

    @classmethod
    def as_form(
        cls,
        student_id: int = Form(...),
        report_type: str = Form(...),
        description: str = Form(...),
    ):
        return cls(
            student_id=student_id,
            report_type=report_type,
            description=description,
        )


class SupportReportUpdate(BaseModel):
    report_type: Optional[str] = None
    description: Optional[str] = None
    ruta_foto: Optional[str] = None # Para guardar la URL si se sube foto

    @classmethod
    def as_form(
        cls,
        report_type: Optional[str] = Form(None),
        description: Optional[str] = Form(None),
    ):
        return cls(
            report_type=report_type,
            description=description,
        )

class SupportReportUpdateAdmin(BaseModel):
    report_type: Optional[str] = None
    description: Optional[str] = None
    ruta_foto: Optional[str] = None
    status: Optional[str] = None

class SupportReportGet(SupportReportBase):
    id: int
    student_id: int

class SupportReportOut(BaseModel):
    id: int
    student_id: int
    report_type: str
    description: str
    status: str
    ruta_foto: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
        
        
class SupportEmailOtpRequest(BaseModel):
    student_id: int


class SupportEmailOtpVerify(BaseModel):
    student_id: int
    codigo: str        


class SupportReportAdminOut(BaseModel):
    id: int
    student_id: int
    report_type: str
    description: str
    status: str
    ruta_foto: Optional[str] = None
    image_url: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True
        
        
class SupportReportImageUrlOut(BaseModel):
    report_id: int
    ruta_foto: Optional[str] = None
    image_url: Optional[str] = None
    
class SupportReportAdminEmailRequest(BaseModel):
    subject: str
    message: str
    status: Optional[str] = None