from sqlalchemy import create_engine, Column, Integer, String, Boolean, DateTime, Text
from sqlalchemy.orm import declarative_base, sessionmaker
from datetime import datetime

from config import DATABASE_URL

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()

class Message(Base):
    __tablename__ = "messages"
    id = Column(Integer, primary_key=True, index=True)
    sender = Column(String(200), nullable=False)
    subject = Column(String(300), nullable=False)
    body = Column(Text, default="")
    read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {"id": self.id, "from": self.sender, "subject": self.subject, "body": self.body, "read": self.read, "created_at": self.created_at.isoformat() if self.created_at else None}

Base.metadata.create_all(bind=engine)
