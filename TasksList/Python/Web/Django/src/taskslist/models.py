from django.db import models

class Task(models.Model):
    title = models.CharField(max_length=300)
    description = models.TextField(blank=True, default="")
    completed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
