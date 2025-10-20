# taiga/cicd/github.py
import os
import requests
import time
from datetime import datetime

# # ===== 配置（优先从环境变量读取） =====
# # 请在运行环境设置真实 token
# OWNER = os.getenv("GITHUB_OWNER", "atmisboru")
# REPO = os.getenv("GITHUB_REPO", "pytest-github-actions-example")
# WORKFLOW_ID = os.getenv("GITHUB_WORKFLOW_ID", "run_test.yml")
# HEADERS = {"Authorization": f"Bearer {GITHUB_TOKEN}"}


def trigger_workflow():
    url = f"https://api.github.com/repos/{OWNER}/{REPO}/actions/workflows/{WORKFLOW_ID}/dispatches"
    payload = {"ref": "master"}
    r = requests.post(url, headers=HEADERS, json=payload)
    if r.status_code != 204:
        raise Exception(f"Failed to dispatch workflow: {r.status_code} - {r.text}")


def get_latest_run():
    url = f"https://api.github.com/repos/{OWNER}/{REPO}/actions/workflows/{WORKFLOW_ID}/runs"
    r = requests.get(url, headers=HEADERS)
    r.raise_for_status()
    runs = r.json().get("workflow_runs", [])
    if not runs:
        raise Exception("No runs found.")
    return runs[0]


def get_jobs(run_id):
    url = f"https://api.github.com/repos/{OWNER}/{REPO}/actions/runs/{run_id}/jobs"
    r = requests.get(url, headers=HEADERS)
    r.raise_for_status()
    return r.json().get("jobs", [])


def run_workflow_and_collect_data(poll_interval_start=5, poll_interval_loop=10, max_wait_seconds=600):
    """
    同步触发 workflow,等待完成并返回结构化 JSON:
    {
      "run_id": <id>,
      "jobs": [
         {"job_name": "...", "steps": [{"name": "...", "duration": 1.23}, ...]},
         ...
      ]
    }

    参数:
    - poll_interval_start: 触发后首次轮询间隔（秒）
    - poll_interval_loop: 运行过程中轮询间隔（秒）
    - max_wait_seconds: 最大等待时间（避免无限等待），达到则抛异常
    """
    trigger_workflow()

    # 等待 workflow 被创建/开始
    run = None
    waited = 0
    while not run:
        time.sleep(poll_interval_start)
        waited += poll_interval_start
        run = get_latest_run()
        # 如果 status 不是 queued，说明已经进入 running 或 completed
        if run.get("status") != "queued":
            break
        if waited > max_wait_seconds:
            raise Exception("Timed out waiting for workflow to start.")

    run_id = run["id"]

    # 等待 workflow 完成
    waited = 0
    while True:
        run = get_latest_run()
        status = run.get("status")
        if status == "completed":
            break
        time.sleep(poll_interval_loop)
        waited += poll_interval_loop
        if waited > max_wait_seconds:
            raise Exception("Timed out waiting for workflow to complete.")

    jobs = get_jobs(run_id)

    result = []
    for job in jobs:
        steps_list = []
        for step in job.get("steps", []):
            start, end = step.get("started_at"), step.get("completed_at")
            if start and end:
                # 转为 datetime 并计算秒
                start_dt = datetime.fromisoformat(start.replace("Z", "+00:00"))
                end_dt = datetime.fromisoformat(end.replace("Z", "+00:00"))
                duration = (end_dt - start_dt).total_seconds()
                steps_list.append({"name": step.get("name"), "duration": duration})
        result.append({"job_name": job.get("name"), "steps": steps_list})

    return {"run_id": run_id, "jobs": result}

