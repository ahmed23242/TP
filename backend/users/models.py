from django.contrib.auth.models import AbstractUser
from django.db import models

# Create your models here.

class User(AbstractUser):
    ROLES = (
        ('citizen', 'Citizen'),
        ('admin', 'Administrator'),
    )
    
    role = models.CharField(max_length=10, choices=ROLES, default='citizen')
    phone_number = models.CharField(max_length=15, blank=True)
    
    class Meta:
        db_table = 'users'
        
    def __str__(self):
        return self.username
