import os
from dotenv import load_dotenv

# Carga las variables desde tu archivo .env
load_dotenv()

class Settings:
    # Si la variable no existe en el .env, el valor será None
    GCS_BUCKET_NAME: str | None = os.getenv("GCS_BUCKET_NAME")
    GCS_FOLDER_ALERTS: str | None = os.getenv("GCS_FOLDER_ALERTS")
    GCS_PROJECT_ID: str | None = os.getenv("GCS_PROJECT_ID")
    
    SUPPORT_ADMIN_EMAIL: str | None = os.getenv("SUPPORT_ADMIN_EMAIL")
    # Google Cloud Storage
    GCS_SIGNER_SERVICE_ACCOUNT: str | None = os.getenv("GCS_SIGNER_SERVICE_ACCOUNT")

settings = Settings()