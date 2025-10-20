# taiga/cicd/views.py
from django.http import JsonResponse
from django.views import View
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt

from taiga.cicd.services.github import run_workflow_and_collect_data


@method_decorator(csrf_exempt, name='dispatch')
class CicdRunView(View):
    """
    POST /api/cicd/run  -> 触发 workflow,等待完成,返回结果（同步阻塞）
    """
    
    def post(self, request, *args, **kwargs):
        try:
            data = run_workflow_and_collect_data()
            return JsonResponse(data, status=200)
        except Exception as e:
            return JsonResponse({"error": str(e)}, status=500)
