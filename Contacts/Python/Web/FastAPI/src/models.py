from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.orm import declarative_base, sessionmaker

from config import DATABASE_URL

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()

class Contact(Base):
    __tablename__ = "contacts"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False)
    phone = Column(String(50), default="")
    email = Column(String(200), default="")

    def to_dict(self):
        return {"id": self.id, "name": self.name, "phone": self.phone, "email": self.email}

Base.metadata.create_all(bind=engine)
