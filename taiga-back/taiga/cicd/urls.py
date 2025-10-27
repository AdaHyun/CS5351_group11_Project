from django.urls import path
from .views import CicdTriggerView, CicdRunSnapshotView, CicdRunSyncView  # 同步版可选

urlpatterns = [
    path("run/", CicdTriggerView.as_view(), name="cicd-run"),                 # 触发 → 立返 run_id
    path("runs/<int:run_id>/", CicdRunSnapshotView.as_view(), name="cicd-run-snapshot"),  # 按 run_id 取进度
    path("run-sync/", CicdRunSyncView.as_view(), name="cicd-run-sync"),       # 可选：原同步阻塞接口
]

