from django.urls import path

from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('api/generate', views.generate, name='generate'),
    path('openapi.json', views.openapi_spec, name='openapi_spec'),
    path('swagger', views.swagger, name='swagger'),
]
