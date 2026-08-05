from django.urls import path

from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('api/state', views.state, name='state'),
    path('api/start', views.start, name='start'),
    path('api/stop', views.stop, name='stop'),
    path('api/reset', views.reset, name='reset'),
    path('api/lap', views.lap, name='lap'),
]
