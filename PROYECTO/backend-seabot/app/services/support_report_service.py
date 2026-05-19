from sqlalchemy.orm import Session
from app.models.student_model import Student
from app.repositories import support_report_repository
from app.schemas.support_report_schema import SupportReportCreate, SupportReportUpdate, SupportReportUpdateAdmin
from fastapi import UploadFile
from app.services.email_service import send_support_report_confirmation_to_user, send_support_report_notification_to_admin
from app.services.gcs_service import upload_support_report_image
from app.core.config import settings
from app.services.gcs_service import generate_signed_url
from app.models.student_model import Student
from app.services.email_service import send_support_admin_response_to_user

ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp", "image/jpg"}

def register(db: Session, objecto: SupportReportCreate, foto: UploadFile | None = None):
    student = db.query(Student).filter(Student.id == objecto.student_id).first()

    if not student:
        raise ValueError("El estudiante no existe")

    if not student.correo:
        raise ValueError("El estudiante no tiene un correo registrado")

    if not student.correo.lower().endswith("@gmail.com"):
        raise ValueError("El correo registrado debe ser una cuenta de Gmail")

    if not student.correo_verificado:
        raise ValueError("Debe verificar su correo antes de enviar un reporte")

    image_url = None

    if foto and foto.filename:
        if foto.content_type not in ALLOWED_IMAGE_TYPES:
            raise ValueError("Formato de imagen no permitido")

        try:
            image_url = upload_support_report_image(foto, objecto.student_id)
        except Exception as e:
            raise ValueError(f"Error al subir la imagen a la nube: {str(e)}")

    objecto.ruta_foto = image_url

    report = support_report_repository.create(db, objecto)

    try:
        send_support_report_confirmation_to_user(
            to_email=student.correo,
            report_type=objecto.report_type,
            description=objecto.description
        )

        send_support_report_notification_to_admin(
            admin_email=settings.SUPPORT_ADMIN_EMAIL,
            student_email=student.correo,
            student_id=student.id,
            report_type=objecto.report_type,
            description=objecto.description,
            ruta_foto=objecto.ruta_foto
        )

    except Exception as e:
        print(f"Error enviando correos de soporte: {str(e)}")

    return report

def list_all(db: Session):
    return support_report_repository.get(db)

def find_by_id(db: Session, object_id: int):
    return support_report_repository.get_by_id(db, object_id)

def modify(db: Session, object_id: int, objecto: SupportReportUpdate, foto: UploadFile | None = None):
    # 1. Buscar la alerta actual para saber quién es el ciudadano
    db_report = support_report_repository.get_by_id(db, object_id)
    if not db_report:
        raise ValueError("Alerta no encontrada")

    # 2. Si hay foto nueva, subirla
    if foto and foto.filename:
        # Reutilizamos tu función de gcs_service
        url = upload_support_report_image(foto, db_report.student_id)
        objecto.ruta_foto = url

    return support_report_repository.update(db, object_id, objecto)


ALLOWED_STATUS = ["Recibido", "En proceso", "Cerrado"]
def patch(db: Session, object_id: int, objecto: SupportReportUpdateAdmin):
    if objecto.status is not None and objecto.status not in ALLOWED_STATUS:
        raise ValueError("Estado no válido. Use: Recibido, En proceso o Cerrado")
    return support_report_repository.patch(db, object_id, objecto)

def remove(db: Session, object_id: int):
    return support_report_repository.delete(db, object_id)

 

def list_all_admin(db: Session):
    reports = support_report_repository.get(db)

    result = []

    for report in reports:
        result.append({
            "id": report.id,
            "student_id": report.student_id,
            "report_type": report.report_type,
            "description": report.description,
            "status": report.status,
            "ruta_foto": report.ruta_foto,
            "image_url": None,
            "created_at": report.created_at,
            "updated_at": report.updated_at,
        })

    return result


def get_report_signed_image(db: Session, report_id: int):
    report = support_report_repository.get_by_id(db, report_id)

    if not report:
        raise ValueError("Reporte no encontrado")

    if not report.ruta_foto:
        raise ValueError("Este reporte no tiene imagen adjunta")

    try:
        image_url = generate_signed_url(report.ruta_foto)
    except Exception as e:
        print(f"Error generando signed URL para reporte {report.id}: {repr(e)}")
        raise ValueError("No se pudo generar la URL de la imagen")

    return {
        "report_id": report.id,
        "ruta_foto": report.ruta_foto,
        "image_url": image_url,
    }
    
def send_admin_email_to_user(db: Session, report_id: int, subject: str, message: str, status: str | None = None):
    report = support_report_repository.get_by_id(db, report_id)

    if not report:
        raise ValueError("Reporte no encontrado")

    student = db.query(Student).filter(Student.id == report.student_id).first()

    if not student:
        raise ValueError("El estudiante asociado al reporte no existe")

    if not student.correo:
        raise ValueError("El estudiante no tiene un correo registrado")

    if status is not None:
        if status not in ALLOWED_STATUS:
            raise ValueError("Estado no válido. Use: Recibido, En proceso o Cerrado")

        report.status = status
        db.commit()
        db.refresh(report)

    try:
        send_support_admin_response_to_user(
            to_email=student.correo,
            report_id=report.id,
            report_type=report.report_type,
            status=report.status,
            subject=subject,
            message=message
        )
    except Exception as e:
        print(f"Error enviando correo administrativo de soporte: {repr(e)}")
        raise ValueError("No se pudo enviar el correo al usuario")

    return {
        "message": "Correo enviado correctamente al usuario",
        "report_id": report.id,
        "student_email": student.correo,
        "status": report.status
    }