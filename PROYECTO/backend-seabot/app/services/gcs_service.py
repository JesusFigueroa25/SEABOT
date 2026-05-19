from uuid import uuid4
from google.cloud import storage
from fastapi import UploadFile
from datetime import timedelta
from datetime import timedelta
import google.auth
from google.auth.transport.requests import Request
from google.cloud import storage
from app.core.config import settings

# En storage_service.py
def upload_support_report_image(file: UploadFile, student_id: int) -> str:
    # Asegúrate de que el cliente use el proyecto de cuota si es necesario
    client = storage.Client(settings.GCS_PROJECT_ID) 
    bucket = client.bucket(settings.GCS_BUCKET_NAME)

    extension = ""
    if file.filename and "." in file.filename:
        extension = "." + file.filename.split(".")[-1].lower()

    blob_name = f"{settings.GCS_FOLDER_ALERTS}/student_{student_id}/{uuid4().hex}{extension}"
    blob = bucket.blob(blob_name)

    # CORRECCIÓN: Asegurar que el puntero esté al inicio antes de leer
    file.file.seek(0) 
    content = file.file.read() 
    
    blob.upload_from_string(
        content,
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