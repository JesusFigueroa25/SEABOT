from sqlalchemy import Column, Integer, String, Float, ForeignKey, Boolean, Date, DateTime, Text
from sqlalchemy.orm import relationship
from app.database.database import Base


class HelpResource(Base):
    __tablename__ = "help_resources"

    id = Column(Integer, primary_key=True, index=True)
    name_resource = Column(String(100))  
    enable = Column(Boolean)
    #Nuevas Columnsa
    # 🟣 Nuevas columnas añadidas
    description = Column(Text, nullable=True)          # Descripción o resumen del recurso
    resource_type = Column(String(50), nullable=True)  # Tipo de recurso (Video, Artículo, Guía, etc.)
    url = Column(Text, nullable=True)                  # Enlace o ubicación del recurso
