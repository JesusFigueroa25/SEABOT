from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from app.database.database import get_db
from app.schemas.support_report_schema import SupportReportImageUrlOut, SupportReportOut, SupportReportCreate, SupportReportUpdate, SupportReportUpdateAdmin, SupportReportAdminEmailRequest
from app.services import support_report_service
from app.schemas.support_report_schema import SupportEmailOtpRequest, SupportEmailOtpVerify
from app.services import support_email_verification_service
from app.schemas.support_report_schema import SupportReportAdminOut

router = APIRouter(prefix="/supports", tags=["Reportes a Soporte"])

#Reporte guardado + imagen en Cloud Storage
@router.post("/", status_code=status.HTTP_201_CREATED)  
def create(
    objecto: SupportReportCreate = Depends(SupportReportCreate.as_form),
    foto: UploadFile | None = File(None),
    db: Session = Depends(get_db)
):
    try:
        support_report_service.register(db, objecto, foto)
        return {"message": "Reporte de soporte creado correctamente"}
    except ValueError as e:
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/", response_model=list[SupportReportOut])
def get_objects(db: Session = Depends(get_db)):
    return support_report_service.list_all(db)

@router.get("/{Obj_id}", response_model=SupportReportOut)
def get_obj(Obj_id: int, db: Session = Depends(get_db)):
    Objecto = support_report_service.find_by_id(db, Obj_id)
    if not Objecto:
        raise HTTPException(status_code=404, detail="Object not found")
    return Objecto

@router.put("/{Obj_id}", status_code=status.HTTP_200_OK) 
def update(
    Obj_id: int, 
    objecto: SupportReportUpdate = Depends(SupportReportUpdate.as_form),
    foto: UploadFile | None = File(None),
    db: Session = Depends(get_db)
):
    return support_report_service.modify(db, Obj_id, objecto, foto)

#Modificar estado
@router.patch("/{Obj_id}", status_code=status.HTTP_200_OK)
def patch_alert(Obj_id: int, objecto: SupportReportUpdateAdmin, db: Session = Depends(get_db)):
    try:
        updated = support_report_service.patch(db, Obj_id, objecto)
        if not updated:
            raise HTTPException(status_code=404, detail="SupportReport not found")

        return {
            "message": "Estado del reporte actualizado correctamente",
            "report_id": updated.id,
            "nuevo_estado": updated.status
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.delete("/{Obj_id}")
def delete(Obj_id: int, db: Session = Depends(get_db)):
    return support_report_service.remove(db, Obj_id)

 #Soporte

@router.post("/email/send-code")
def send_support_email_code(
    data: SupportEmailOtpRequest,
    db: Session = Depends(get_db)
):
    try:
        return support_email_verification_service.generate_support_email_otp(
            db,
            data.student_id
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/email/verify-code")
def verify_support_email_code(
    data: SupportEmailOtpVerify,
    db: Session = Depends(get_db)
):
    try:
        return support_email_verification_service.verify_support_email_otp(
            db,
            data.student_id,
            data.codigo
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/email/status/{student_id}")
def get_support_email_status(
    student_id: int,
    db: Session = Depends(get_db)
):
    try:
        return support_email_verification_service.get_support_email_status(
            db,
            student_id
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    

@router.get("/admin/list", response_model=list[SupportReportAdminOut])
def get_reports_admin(db: Session = Depends(get_db)):
    return support_report_service.list_all_admin(db)

@router.get("/admin/{report_id}/image-url", response_model=SupportReportImageUrlOut)
def get_report_image_url(report_id: int, db: Session = Depends(get_db)):
    try:
        return support_report_service.get_report_signed_image(db, report_id)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    
@router.post("/admin/{report_id}/send-email")
def send_admin_email_to_report_user(
    report_id: int,
    data: SupportReportAdminEmailRequest,
    db: Session = Depends(get_db)
):
    try:
        return support_report_service.send_admin_email_to_user(
            db=db,
            report_id=report_id,
            subject=data.subject,
            message=data.message,
            status=data.status
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
