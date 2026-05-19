import random
import smtplib
from datetime import datetime, timedelta

from email_validator import validate_email, EmailNotValidError
from sqlalchemy.orm import Session

from app.models.student_model import Student
from app.models.support_email_verification_model import SupportEmailVerificationToken
from app.services.email_service import send_support_otp_email


def generate_support_email_otp(db: Session, student_id: int):
    student = db.query(Student).filter(Student.id == student_id).first()

    if not student:
        raise ValueError("El estudiante no existe")

    if not student.correo:
        raise ValueError("El estudiante no tiene un correo registrado")

    correo = student.correo.strip().lower()

    try:
        email_info = validate_email(correo, check_deliverability=False)
        correo_normalizado = email_info.normalized.lower()
    except EmailNotValidError:
        raise ValueError("El correo registrado no tiene un formato válido")

    if not correo_normalizado.endswith("@gmail.com"):
        raise ValueError("El correo registrado debe ser una cuenta de Gmail")

    codigo = str(random.randint(100000, 999999))

    token = SupportEmailVerificationToken(
        student_id=student.id,
        codigo=codigo,
        expires_at=datetime.utcnow() + timedelta(minutes=10),
        used=False
    )

    db.add(token)
    db.commit()
    db.refresh(token)

    try:
        send_support_otp_email(correo_normalizado, codigo)
    except smtplib.SMTPRecipientsRefused:
        raise ValueError(
            "No se pudo enviar el código. Verifica que el correo registrado sea correcto"
        )
    except smtplib.SMTPAuthenticationError:
        raise ValueError("Error de autenticación del correo de soporte")
    except smtplib.SMTPException:
        raise ValueError("No se pudo enviar el código de verificación. Inténtalo nuevamente")
    except Exception as e:
        print(f"Error enviando OTP de soporte: {repr(e)}")
        raise ValueError("Ocurrió un error al enviar el código de verificación")

    return {
        "message": "Código de verificación enviado correctamente",
        "correo": correo_normalizado
    }


def verify_support_email_otp(db: Session, student_id: int, codigo: str):
    student = db.query(Student).filter(Student.id == student_id).first()

    if not student:
        raise ValueError("El estudiante no existe")

    token = (
        db.query(SupportEmailVerificationToken)
        .filter(
            SupportEmailVerificationToken.student_id == student_id,
            SupportEmailVerificationToken.codigo == codigo,
            SupportEmailVerificationToken.used == False
        )
        .order_by(SupportEmailVerificationToken.created_at.desc())
        .first()
    )

    if not token:
        raise ValueError("Código inválido")

    if token.expires_at < datetime.utcnow():
        raise ValueError("El código ha expirado")

    token.used = True
    student.correo_verificado = True
    student.correo_verified_at = datetime.utcnow()

    db.commit()

    return {
        "message": "Correo verificado correctamente",
        "correo_verificado": True
    }
    
    
def get_support_email_status(db: Session, student_id: int):
    student = db.query(Student).filter(Student.id == student_id).first()

    if not student:
        raise ValueError("El estudiante no existe")

    if not student.correo:
        return {
            "student_id": student.id,
            "correo": None,
            "correo_verificado": False,
            "message": "El estudiante no tiene un correo registrado"
        }

    return {
        "student_id": student.id,
        "correo": student.correo,
        "correo_verificado": bool(student.correo_verificado),
        "message": "Estado del correo obtenido correctamente"
    }