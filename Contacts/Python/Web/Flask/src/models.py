from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

class Contact(db.Model):
    __tablename__ = "contacts"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False)
    phone = db.Column(db.String(50), default="")
    email = db.Column(db.String(200), default="")

    def to_dict(self):
        return {"id": self.id, "name": self.name, "phone": self.phone, "email": self.email}
