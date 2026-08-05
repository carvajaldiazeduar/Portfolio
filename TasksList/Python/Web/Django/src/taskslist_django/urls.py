from django.urls import include, path

urlpatterns = [
    path('', include('taskslist.urls')),
]
