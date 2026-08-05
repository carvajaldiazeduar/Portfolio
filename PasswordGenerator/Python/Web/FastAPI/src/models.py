from sqlalchemy import create_engine, Column, Integer, String, DateTime
from sqlalchemy.orm import declarative_base, sessionmaker
from datetime import datetime

from config import DATABASE_URL

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()

class PasswordEntry(Base):
    __tablename__ = "password_entries"
    id = Column(Integer, primary_key=True, index=True)
    password = Column(String(500), nullable=False)
    length = Column(Integer, default=16)
    created_at = Column(DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {"id": self.id, "password": self.password, "length": self.length, "created_at": self.created_at.isoformat() if self.created_at else None}

Base.metadata.create_all(bind=engine)
