from django.db import models

class Contact(models.Model):
    name = models.CharField(max_length=200)
    phone = models.CharField(max_length=50, blank=True, default="")
    email = models.EmailField(max_length=200, blank=True, default="")
