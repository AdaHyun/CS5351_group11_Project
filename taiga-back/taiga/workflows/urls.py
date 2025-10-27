from django.urls import path
from .views import WorkflowsView, WorkflowDetailView

urlpatterns = [
    path("", WorkflowsView.as_view(), name="workflow-list-or-upload"),
    path("<str:name>/", WorkflowDetailView.as_view(), name="workflow-detail"),
]

