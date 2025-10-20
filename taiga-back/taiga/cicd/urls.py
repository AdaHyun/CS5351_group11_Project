# taiga/cicd/urls.py
from django.urls import path
from .views import CicdRunView

urlpatterns = [
    path("run/", CicdRunView.as_view(), name="cicd-run"),
]

