import json
from django.http import JsonResponse
from django.views import View
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt

from taiga.cicd.services.github import (
    trigger_and_return_run,    # 新：触发即返
    fetch_run_snapshot,        # 新：带进度快照
    run_workflow_and_collect_data,  # 兼容：原同步
)

@method_decorator(csrf_exempt, name='dispatch')
class CicdTriggerView(View):
    # POST /api/cicd/run/
    def post(self, request, *args, **kwargs):
        try:
            payload = {}
            if request.body:
                try:
                    payload = json.loads(request.body.decode("utf-8"))
                except Exception:
                    payload = {}
            ref = payload.get("ref")
            inputs = payload.get("inputs")
            data = trigger_and_return_run(ref=ref, inputs=inputs)
            return JsonResponse(data, status=201)
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=500)

class CicdRunSnapshotView(View):
    # GET /api/cicd/runs/<run_id>/
    def get(self, request, run_id, *args, **kwargs):
        try:
            data = fetch_run_snapshot(int(run_id))
            return JsonResponse(data, status=200)
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=500)

@method_decorator(csrf_exempt, name='dispatch')
class CicdRunSyncView(View):
    # POST /api/cicd/run-sync/  （可选保留老行为）
    def post(self, request, *args, **kwargs):
        try:
            data = run_workflow_and_collect_data()
            return JsonResponse(data, status=200)
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=500)

