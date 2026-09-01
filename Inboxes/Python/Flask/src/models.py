from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

db = SQLAlchemy()

class Message(db.Model):
    __tablename__ = "messages"
    id = db.Column(db.Integer, primary_key=True)
    sender = db.Column(db.String(200), nullable=False)
    subject = db.Column(db.String(300), nullable=False)
    body = db.Column(db.Text, default="")
    read = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "from": self.sender,
            "subject": self.subject,
            "body": self.body,
            "read": self.read,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
