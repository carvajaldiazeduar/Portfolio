from django.urls import path

from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('api/contacts', views.contacts_handler, name='contacts'),
    path('api/contacts/<int:contact_id>', views.contact_detail, name='contact_detail'),
]
