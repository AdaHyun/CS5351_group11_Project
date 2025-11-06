import json
from django.http import JsonResponse
from django.views import View
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt

from .services import upload_workflow, list_workflows, get_workflow

@method_decorator(csrf_exempt, name='dispatch')
class WorkflowsView(View):
    """
    GET  /api/workflows/?branch=master   -> 列表
    POST /api/workflows/                 -> 上传（JSON 或 multipart）
    """
    def get(self, request, *args, **kwargs):
        try:
            branch = request.GET.get("branch")
            data = list_workflows(branch=branch)
            return JsonResponse(data, status=200)
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=500)

    def post(self, request, *args, **kwargs):
        try:
            # multipart
            if request.FILES:
                f = request.FILES.get("file")
                if not f:
                    return JsonResponse({"error": "file is required"}, status=400)
                name = request.POST.get("name") or f.name
                branch = request.POST.get("branch")
                content = f.read().decode("utf-8")
                data = upload_workflow(name=name, content=content, branch=branch)
                return JsonResponse(data, status=201)

            # JSON
            payload = {}
            if request.body:
                try:
                    payload = json.loads(request.body.decode("utf-8"))
                except Exception:
                    payload = {}
            name = payload.get("name")
            content = payload.get("content")
            branch = payload.get("branch")
            if not name or not content:
                return JsonResponse({"error": "name and content are required"}, status=400)

            data = upload_workflow(name=name, content=content, branch=branch)
            return JsonResponse(data, status=201)
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=500)

class WorkflowDetailView(View):
    """GET /api/workflows/<name>/?branch=master -> 单个查询"""
    def get(self, request, name, *args, **kwargs):
        try:
            branch = request.GET.get("branch")
            data = get_workflow(name=name, branch=branch)
            return JsonResponse(data, status=200)
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=500)

