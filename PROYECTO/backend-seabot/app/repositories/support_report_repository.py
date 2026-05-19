from sqlalchemy.orm import Session
from app.models.support_report_model import SupportReport
from app.schemas.support_report_schema import SupportReportCreate, SupportReportUpdate
from sqlalchemy import func

def create(db: Session, objeto: SupportReportCreate):
    db_object = SupportReport(
        student_id=objeto.student_id,
        report_type=objeto.report_type,
        description=objeto.description,
        ruta_foto=objeto.ruta_foto,
        status = "Recibido"
    )
    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return db_object


def get(db: Session):
    return (
        db.query(SupportReport)
        .order_by(SupportReport.created_at.desc())
        .all()
    )

def get_by_id(db: Session, object_id: int):
    return db.query(SupportReport).filter(SupportReport.id == object_id).first()

def update(db: Session, object_id: int, objeto: SupportReportUpdate):
    db_object = get_by_id(db, object_id)

    if db_object:
        if objeto.report_type is not None:
            db_object.report_type = objeto.report_type

        if objeto.description is not None:
            db_object.description = objeto.description

        if objeto.ruta_foto is not None:
            db_object.ruta_foto = objeto.ruta_foto

        db.commit()
        db.refresh(db_object)

    return db_object

def patch(db: Session, object_id: int, objeto: SupportReportUpdate):
    db_object = get_by_id(db, object_id)
    if not db_object:
        return None

    update_data = objeto.dict(exclude_unset=True)

    for key, value in update_data.items():
        setattr(db_object, key, value)

    db.commit()
    db.refresh(db_object)
    return db_object

def delete(db: Session, object_id: int):
    db_object = get_by_id(db, object_id)
    if db_object:
        db.delete(db_object)
        db.commit()
    return db_object
 