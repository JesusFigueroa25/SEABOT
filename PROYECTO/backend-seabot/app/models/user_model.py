from sqlalchemy import Column, Integer, String, Float,Text, ForeignKey, Boolean, Date, DateTime, text
from sqlalchemy.orm import relationship
from app.database.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    nameuser = Column(String(50), unique=True, nullable=False)
    password = Column(Text, nullable=False) 
    enable = Column(Boolean, nullable=False, default=True, server_default=text("true"))
    role = Column(String(20), nullable=False)

    student = relationship("Student", back_populates="user")


