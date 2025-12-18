from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# URL de conexión a PostgreSQL
#DATABASE_URL = "postgresql://postgres:password@localhost:5432/seabot_db"
DATABASE_URL = "postgresql://postgres:seaBot_251003@34.95.132.202/sea_db"


# Crear motor de conexión
engine = create_engine(DATABASE_URL, echo=True)

# Crear sesión (se usará para consultas)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Clase base para modelos
Base = declarative_base()


# Dependencia: obtener una sesión de la base de datos
def get_db():
    db = SessionLocal()
    try:
        yield db   # se entrega la sesión al endpoint
    finally:
        db.close()  # al terminar, se cierra la conexión
