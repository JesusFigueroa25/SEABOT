from sqlalchemy.orm import Session
from app.models.support_report_model import SupportReport
from app.schemas.support_report_schema import SupportReportCreate, SupportReportUpdate
from app.utils.datetime_utils import now_lima_naive

def create(db: Session, objeto: SupportReportCreate):
    now = now_lima_naive()

    db_object = SupportReport(
        student_id=objeto.student_id,
        report_type=objeto.report_type,
        description=objeto.description,
        ruta_foto=objeto.ruta_foto,
        status = "Recibido",
        created_at=now,
        updated_at=None
    )
    db.add(db_object)
    db.commit()
    db.refresh(db_object)
    return db_object

def update(db: Session, object_id: int, objeto: SupportReportUpdate):
    db_object = get_by_id(db, object_id)

    if db_object:
        changed = False
        
        if objeto.report_type is not None:
            db_object.report_type = objeto.report_type
            changed = True

        if objeto.description is not None:
            db_object.description = objeto.description
            changed = True

        if objeto.ruta_foto is not None:
            db_object.ruta_foto = objeto.ruta_foto
            changed = True

        if changed:
            db_object.updated_at = now_lima_naive()

        db.commit()
        db.refresh(db_object)

    return db_object

def patch(db: Session, object_id: int, objeto: SupportReportUpdate):
    db_object = get_by_id(db, object_id)
    if not db_object:
        return None

    update_data = objeto.dict(exclude_unset=True, exclude_none=True)

    for key, value in update_data.items():
        setattr(db_object, key, value)

    if update_data:
        db_object.updated_at = now_lima_naive()

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

def delete(db: Session, object_id: int):
    db_object = get_by_id(db, object_id)
    if db_object:
        db.delete(db_object)
        db.commit()
    return db_object
 