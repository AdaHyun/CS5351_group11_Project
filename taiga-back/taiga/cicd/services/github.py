# taiga/cicd/services/github.py
import os
import time
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional

import requests

# ===== 配置（测试阶段按你要求：token 写在文件里；生产请改为环境变量）=====
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN", "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")
OWNER = os.getenv("GITHUB_OWNER", "atmisboru")
REPO = os.getenv("GITHUB_REPO", "pytest-github-actions-example")
WORKFLOW_ID = os.getenv("GITHUB_WORKFLOW_ID", "run_test.yml")
DEFAULT_REF = os.getenv("GITHUB_DEFAULT_REF", "master")

API_BASE = f"https://api.github.com/repos/{OWNER}/{REPO}"
HEADERS = {
    "Authorization": f"Bearer {GITHUB_TOKEN}",
    "Accept": "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
}
REQUEST_TIMEOUT = 20
MAX_PER_PAGE = 100


# ========= 基础请求封装 =========
def _req(method: str, url: str, **kwargs) -> requests.Response:
    kwargs.setdefault("headers", HEADERS)
    kwargs.setdefault("timeout", REQUEST_TIMEOUT)

    backoff = [0, 0.5, 1, 2, 4]
    last_exc = None
    for delay in backoff:
        if delay:
            time.sleep(delay)
        try:
            r = requests.request(method, url, **kwargs)
            # 简单的速率限制处理
            if r.status_code == 429:
                ra = r.headers.get("Retry-After")
                try:
                    time.sleep(float(ra) if ra else 2)
                except Exception:
                    time.sleep(2)
                continue
            if r.status_code == 403 and "rate limit" in (r.text or "").lower():
                time.sleep(5)
                continue
            return r
        except requests.RequestException as e:
            last_exc = e
            continue
    if last_exc:
        raise Exception(f"请求失败: {last_exc}")
    raise Exception("请求失败（未知原因）")


def _parse_iso8601(ts: Optional[str]) -> Optional[datetime]:
    if not ts:
        return None
    # GitHub 时间戳通常以 Z 结尾
    return datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone(timezone.utc)


def _list_runs(event: Optional[str] = None, branch: Optional[str] = None) -> List[Dict[str, Any]]:
    """列出某 workflow 的 runs，带分页。"""
    params = {"per_page": MAX_PER_PAGE}
    if event:
        params["event"] = event
    if branch:
        params["branch"] = branch
    url = f"{API_BASE}/actions/workflows/{WORKFLOW_ID}/runs"

    out: List[Dict[str, Any]] = []
    page = 1
    while True:
        params["page"] = page
        r = _req("GET", url, params=params)
        r.raise_for_status()
        data = r.json() or {}
        batch = data.get("workflow_runs", []) or []
        out.extend(batch)
        if len(batch) < MAX_PER_PAGE:
            break
        page += 1
    return out


def _get_jobs(run_id: int) -> List[Dict[str, Any]]:
    """获取指定 run 的 jobs（含 steps），带分页。"""
    url = f"{API_BASE}/actions/runs/{run_id}/jobs"
    params = {"per_page": MAX_PER_PAGE}
    jobs: List[Dict[str, Any]] = []
    page = 1
    while True:
        params["page"] = page
        r = _req("GET", url, params=params)
        r.raise_for_status()
        data = r.json() or {}
        batch = data.get("jobs", []) or []
        jobs.extend(batch)
        if len(batch) < MAX_PER_PAGE:
            break
        page += 1
    return jobs


# ========= 原同步版本：触发->等待完成->返回 =========
def trigger_workflow():
    url = f"{API_BASE}/actions/workflows/{WORKFLOW_ID}/dispatches"
    payload = {"ref": DEFAULT_REF}
    r = _req("POST", url, json=payload)
    if r.status_code != 204:
        raise Exception(f"Failed to dispatch workflow: {r.status_code} - {r.text}")


def get_latest_run():
    url = f"{API_BASE}/actions/workflows/{WORKFLOW_ID}/runs"
    r = _req("GET", url)
    r.raise_for_status()
    runs = r.json().get("workflow_runs", [])
    if not runs:
        raise Exception("No runs found.")
    return runs[0]


def get_jobs(run_id):
    return _get_jobs(run_id)


def run_workflow_and_collect_data(poll_interval_start=5, poll_interval_loop=10, max_wait_seconds=600):
    """
    同步触发 workflow，等待完成并返回结构化 JSON（保持你的原有行为）：
    {
      "run_id": <id>,
      "jobs": [
        {"job_name": "...", "steps": [{"name": "...", "duration": 1.23}, ...]},
        ...
      ]
    }
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
                start_dt = _parse_iso8601(start)
                end_dt = _parse_iso8601(end)
                duration = (end_dt - start_dt).total_seconds()
                steps_list.append({"name": step.get("name"), "duration": duration})
        result.append({"job_name": job.get("name"), "steps": steps_list})

    return {"run_id": run_id, "jobs": result}


# ========= 新：触发即返（不等待完成），用于前端轮询 =========
def trigger_and_return_run(ref: Optional[str] = None, inputs: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """
    触发后“尽快”定位本次 run，并立即返回 run_id/html_url/status（不等待完成）。
    """
    ref = ref or DEFAULT_REF
    dispatch_time = datetime.now(timezone.utc)

    # 触发
    url = f"{API_BASE}/actions/workflows/{WORKFLOW_ID}/dispatches"
    payload: Dict[str, Any] = {"ref": ref}
    if inputs:
        payload["inputs"] = inputs
    r = _req("POST", url, json=payload)
    if r.status_code != 204:
        raise Exception(f"触发失败: {r.status_code} - {r.text}")

    # 定位本次 run（event=workflow_dispatch + branch + created_at >= dispatch_time）
    waited = 0.0
    while waited <= 120:  # 最多等 2 分钟把 run 定位出来
        runs = _list_runs(event="workflow_dispatch", branch=ref)
        for run in runs:  # GitHub 默认倒序
            created_at = _parse_iso8601(run.get("created_at"))
            if created_at and created_at >= dispatch_time:
                return {
                    "run_id": run["id"],
                    "run_html_url": run.get("html_url"),
                    "status": run.get("status"),
                }
        time.sleep(3.0)
        waited += 3.0

    raise Exception("在限定时间内未找到本次触发的 workflow run。")


# ========= 新：轮询快照（带进度），用于进度条显示 =========
def fetch_run_snapshot(run_id: int) -> Dict[str, Any]:
    """
    返回带进度的快照（未完成也会返回进行中状态）：
    - run_progress_pct: 基于“当前可见”的 jobs（completed / total_visible）
    - 每个 job 带 job_progress_pct、completed_steps/total_steps、current_step_index
    - 每个 step 带 is_current/is_done，status/conclusion/时间戳
    """
    # 1) run 概览
    run_url = f"{API_BASE}/actions/runs/{run_id}"
    r1 = _req("GET", run_url)
    r1.raise_for_status()
    run = r1.json()

    # 2) jobs + steps
    jobs_raw = _get_jobs(run_id)
    jobs_out: List[Dict[str, Any]] = []
    completed_jobs = 0

    for job in jobs_raw:
        steps = job.get("steps", []) or []
        total_steps = len(steps)
        completed_steps = 0
        current_step_index = None  # 正在进行的 step 下标（0-based）

        steps_out = []
        for idx, s in enumerate(steps):
            status = s.get("status")            # queued / in_progress / completed
            conclusion = s.get("conclusion")    # completed 后才有
            if status == "completed":
                completed_steps += 1
            elif status == "in_progress" and current_step_index is None:
                current_step_index = idx

            steps_out.append({
                "index": idx,
                "name": s.get("name"),
                "status": status,
                "conclusion": conclusion,
                "started_at": s.get("started_at"),
                "completed_at": s.get("completed_at"),
                "is_current": status == "in_progress",
                "is_done": status == "completed",
            })

        job_status = job.get("status")          # queued / in_progress / completed
        if job_status == "completed":
            completed_jobs += 1

        # Job 进度：完成步数 / 总步数；若总步数为0，则用状态判断（completed=100，否则0）
        job_progress_pct = (
            int(round((completed_steps / total_steps) * 100))
            if total_steps > 0 else (100 if job_status == "completed" else 0)
        )

        jobs_out.append({
            "job_name": job.get("name"),
            "status": job_status,
            "conclusion": job.get("conclusion"),
            "started_at": job.get("started_at"),
            "completed_at": job.get("completed_at"),
            "total_steps": total_steps,
            "completed_steps": completed_steps,
            "current_step_index": current_step_index,   # None 表示当前没有 running 的 step
            "job_progress_pct": job_progress_pct,       # 0–100
            "steps": steps_out,
        })

    total_jobs_visible = len(jobs_raw)
    # Run 进度：基于“当前可见”的 jobs 计算
    run_progress_pct = (
        int(round((completed_jobs / total_jobs_visible) * 100))
        if total_jobs_visible > 0 else (100 if run.get("status") == "completed" else 0)
    )

    return {
        "run_id": run.get("id"),
        "status": run.get("status"),            # queued / in_progress / completed
        "conclusion": run.get("conclusion"),    # 仅 completed 有值
        "run_html_url": run.get("html_url"),
        "branch": run.get("head_branch"),
        "updated_at": run.get("updated_at"),
        "total_jobs_visible": total_jobs_visible,
        "completed_jobs": completed_jobs,
        "run_progress_pct": run_progress_pct,   # 0–100（基于“可见”jobs）
        "jobs": jobs_out,
    }

