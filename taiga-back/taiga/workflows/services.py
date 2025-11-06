import os
import base64
import requests
from typing import Optional, Dict, Any, List

# —— 测试阶段按你要求：token 可以写死；生产改成只读环境变量 ——
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN", "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")
OWNER = os.getenv("GITHUB_OWNER", "atmisboru")
REPO = os.getenv("GITHUB_REPO", "pytest-github-actions-example")
DEFAULT_REF = os.getenv("GITHUB_DEFAULT_REF", "master")

API_BASE = f"https://api.github.com/repos/{OWNER}/{REPO}"
HEADERS = {
    "Authorization": f"Bearer {GITHUB_TOKEN}",
    "Accept": "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
}
REQUEST_TIMEOUT = 20

def _req(method: str, url: str, **kwargs) -> requests.Response:
    kwargs.setdefault("headers", HEADERS)
    kwargs.setdefault("timeout", REQUEST_TIMEOUT)
    return requests.request(method, url, **kwargs)

def upload_workflow(name: str, content: str, branch: Optional[str] = None,
                    message: Optional[str] = None) -> Dict[str, Any]:
    """
    把 workflow 上传到 .github/workflows/<name>（默认补 .yml）
    已存在则覆盖（带 sha）。不做额外校验。
    """
    branch = branch or DEFAULT_REF
    if not (name.endswith(".yml") or name.endswith(".yaml")):
        name = f"{name}.yml"
    path = f".github/workflows/{name}"

    # 先查 sha（存在则更新）
    get_url = f"{API_BASE}/contents/{path}"
    sha = None
    r_get = _req("GET", get_url, params={"ref": branch})
    if r_get.status_code == 200:
        sha = (r_get.json() or {}).get("sha")

    b64 = base64.b64encode(content.encode("utf-8")).decode("utf-8")
    payload = {
        "message": message or f"chore(ci): upload workflow {name}",
        "content": b64,
        "branch": branch,
    }
    if sha:
        payload["sha"] = sha

    r_put = _req("PUT", get_url, json=payload)
    r_put.raise_for_status()
    data = r_put.json() or {}
    return {
        "path": path,
        "branch": branch,
        "commit_sha": (data.get("commit") or {}).get("sha"),
        "content_sha": (data.get("content") or {}).get("sha"),
        "html_url": (data.get("content") or {}).get("html_url"),
    }

def list_workflows(branch: Optional[str] = None) -> Dict[str, Any]:
    """列出 .github/workflows/ 下的文件"""
    branch = branch or DEFAULT_REF
    url = f"{API_BASE}/contents/.github/workflows"
    r = _req("GET", url, params={"ref": branch})
    r.raise_for_status()
    items = r.json() or []
    files = [
        {"name": it.get("name"), "path": it.get("path"),
         "sha": it.get("sha"), "html_url": it.get("html_url")}
        for it in items if it.get("type") == "file"
    ]
    return {"branch": branch, "files": files}

def get_workflow(name: str, branch: Optional[str] = None) -> Dict[str, Any]:
    """查询单个 workflow 是否存在"""
    branch = branch or DEFAULT_REF
    if not (name.endswith(".yml") or name.endswith(".yaml")):
        name = f"{name}.yml"
    path = f".github/workflows/{name}"
    url = f"{API_BASE}/contents/{path}"
    r = _req("GET", url, params={"ref": branch})
    if r.status_code == 404:
        return {"exists": False, "branch": branch, "path": path}
    r.raise_for_status()
    data = r.json() or {}
    return {
        "exists": True,
        "branch": branch,
        "path": path,
        "sha": data.get("sha"),
        "html_url": data.get("html_url"),
    }

