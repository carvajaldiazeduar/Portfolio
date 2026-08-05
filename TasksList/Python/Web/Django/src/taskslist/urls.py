from django.urls import path

from . import views

urlpatterns = [
    path('', views.index, name='index'),
    path('api/tasks', views.tasks_handler, name='tasks'),
    path('api/tasks/<int:task_id>/complete', views.complete_task, name='complete_task'),
    path('api/tasks/<int:task_id>', views.task_detail, name='task_detail'),
]
