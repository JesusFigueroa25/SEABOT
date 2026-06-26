from datetime import datetime, timedelta
import random
from fastapi import HTTPException
from sqlalchemy.orm import Session
from app.models.password_reset_token_model import PasswordResetToken
from app.models.student_model import Student
from app.models.user_model import User
from app.repositories import password_reset_repository, user_repository
from app.security.auth import hash_password
from app.services.email_service import send_reset_email
from app.utils.datetime_utils import now_lima_naive

def _generate_otp_code() -> str:
    return str(random.randint(100000, 999999))

from fastapi import HTTPException

def request_password_reset(db: Session, correo: str):
    student = db.query(Student).filter(Student.correo == correo).first()

    if not student or not student.user_id:
        raise HTTPException(status_code=404, detail="Correo no registrado")

    user = db.query(User).filter(User.id == student.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    password_reset_repository.invalidate_user_tokens(db, user.id)

    otp_code = _generate_otp_code()
    now = now_lima_naive()

    token_row = PasswordResetToken(
        user_id=user.id,
        codigo=otp_code,
        expires_at=now + timedelta(minutes=15),
        used=False,
        created_at=now
    )

    password_reset_repository.create(db, token_row)

    send_reset_email(correo, otp_code)

    return {
        "message": "Código enviado correctamente al correo"
    }


def reset_password(db: Session, codigo: str, new_password: str):
    token_row = password_reset_repository.get_valid_by_code(db, codigo)

    if not token_row:
        raise HTTPException(status_code=400, detail="Código inválido o expirado")

    user = user_repository.get_by_id(db, token_row.user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    user.password = hash_password(new_password)
    db.commit()
    db.refresh(user)

    password_reset_repository.mark_used(db, token_row)

    return {"message": "Contraseña actualizada correctamente"}