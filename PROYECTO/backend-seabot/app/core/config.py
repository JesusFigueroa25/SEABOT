import os

class Settings:
    GCS_BUCKET_NAME: str = os.getenv("GCS_BUCKET_NAME", "seabot-reportes")
    GCS_FOLDER_ALERTS: str = os.getenv("GCS_FOLDER_ALERTS", "support_reports")
    GCS_PROJECT_ID: str = os.getenv("GCS_PROJECT_ID", "project-4f6f56a7-11ef-44b7-995")
    
    SUPPORT_ADMIN_EMAIL: str = os.getenv("SUPPORT_ADMIN_EMAIL","soporte25upc@gmail.com")
     # Google Cloud Storage
    GCS_SIGNER_SERVICE_ACCOUNT: str = os.getenv("GCS_SIGNER_SERVICE_ACCOUNT","993787742289-compute@developer.gserviceaccount.com")

    
settings = Settings()