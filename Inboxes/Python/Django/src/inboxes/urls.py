from django.urls import path

from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('api/messages', views.messages_handler, name='messages'),
    path('api/messages/<int:message_id>', views.message_detail, name='message_detail'),
    path('openapi.json', views.openapi_spec, name='openapi_spec'),
    path('swagger', views.swagger, name='swagger'),
]
