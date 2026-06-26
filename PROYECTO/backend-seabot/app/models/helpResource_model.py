from sqlalchemy import Column, Integer, String, Float, ForeignKey, Boolean, Date, DateTime, Text, text
from sqlalchemy.orm import relationship
from app.database.database import Base


class HelpResource(Base):
    __tablename__ = "help_resources"

    id = Column(Integer, primary_key=True, index=True)
    name_resource = Column(String(100), nullable=False)
    enable = Column(Boolean, nullable=False, server_default=text("true"), default=True)
    description = Column(Text, nullable=True)
    resource_type = Column(String(50), nullable=True)
    url = Column(Text, nullable=True)              
