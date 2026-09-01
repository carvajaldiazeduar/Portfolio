from django.db import models

class PasswordEntry(models.Model):
    password = models.CharField(max_length=500)
    length = models.IntegerField(default=16)
    created_at = models.DateTimeField(auto_now_add=True)
