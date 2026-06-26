import os
from uuid import uuid4
from fastapi import UploadFile
from google.cloud import storage
from datetime import timedelta
import google.auth
from google.auth.transport.requests import Request
from app.core.config import settings

def upload_support_report_image(file: UploadFile, student_id: int) -> str:
    # 1. Inicializar cliente y bucket explícitamente
    client = storage.Client(project=settings.GCS_PROJECT_ID) 
    bucket = client.bucket(settings.GCS_BUCKET_NAME)

    # 2. Extraer extensión de forma más segura (usando os.path)
    extension = ""
    if file.filename:
        _, ext = os.path.splitext(file.filename)
        extension = ext.lower()

    # 3. Construir la ruta (blob name)
    blob_name = f"{settings.GCS_FOLDER_ALERTS}/student_{student_id}/{uuid4().hex}{extension}"
    blob = bucket.blob(blob_name)

    # 4. Asegurar que el puntero esté al inicio
    file.file.seek(0) 
    
    # 5. MEJORA: Subir directamente desde el objeto file (Stream) en lugar de RAM
    blob.upload_from_file(
        file.file,
        content_type=file.content_type
    )

    return blob_name


def generate_signed_url(blob_name: str, expiration_minutes: int = 15) -> str:
    credentials, _ = google.auth.default()
    credentials.refresh(Request())

    if not settings.GCS_SIGNER_SERVICE_ACCOUNT:
        raise ValueError("Falta configurar GCS_SIGNER_SERVICE_ACCOUNT en el entorno")

    client = storage.Client(
        project=settings.GCS_PROJECT_ID,
        credentials=credentials
    )

    bucket = client.bucket(settings.GCS_BUCKET_NAME)
    blob = bucket.blob(blob_name)

    return blob.generate_signed_url(
        version="v4",
        expiration=timedelta(minutes=expiration_minutes),
        method="GET",
        service_account_email=settings.GCS_SIGNER_SERVICE_ACCOUNT,
        access_token=credentials.token,
    )