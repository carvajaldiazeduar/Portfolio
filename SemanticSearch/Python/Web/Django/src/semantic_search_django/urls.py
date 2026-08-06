from django.urls import path
from semantic_search import views

urlpatterns = [
    path("", views.index, name="index"),
    path("api/search/", views.search, name="search"),
    path("api/upload/", views.upload_document, name="upload"),
    path("api/collections/", views.list_collections, name="collections"),
    path("openapi.json", views.openapi_spec, name="openapi_spec"),
    path("swagger", views.swagger, name="swagger"),
]