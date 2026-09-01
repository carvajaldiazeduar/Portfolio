from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

db = SQLAlchemy()

class PasswordEntry(db.Model):
    __tablename__ = "password_entries"
    id = db.Column(db.Integer, primary_key=True)
    password = db.Column(db.String(500), nullable=False)
    length = db.Column(db.Integer, default=16)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "password": self.password,
            "length": self.length,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
