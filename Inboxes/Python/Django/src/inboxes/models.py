from django.db import models

class Message(models.Model):
    sender = models.CharField(max_length=200)
    subject = models.CharField(max_length=300)
    body = models.TextField(blank=True, default="")
    read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
