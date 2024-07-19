import http.client
import json
import os
from typing import Dict, List, Optional
from urllib.parse import ParseResult, urlencode, urlparse


def repstr(string, length) -> str:
    return string * length


def load_dotenv(filepath):
    with open(file=filepath, encoding="utf-8") as f:
        for line in f:
            if line.strip() and not line.startswith("#"):
                key, value = line.strip().split("=", 1)
                os.environ[key] = value


load_dotenv(filepath=".env")


GITLAB_INSTANCE: str = os.getenv("GITLAB_INSTANCE", "hallo")
ACCESS_TOKEN: str = os.getenv("ACCESS_TOKEN", "")

headers: Dict = {"PRIVATE-TOKEN": ACCESS_TOKEN}


def fetch_all_pages(
    conn: http.client.HTTPSConnection, path: str, query_str: Optional[str] = None
) -> List[Dict]:
    results: List[Dict] = []
    page = 1
    per_page = 100

    while True:
        params: str = urlencode(query={"page": page, "per_page": per_page})
        if query_str is not None:
            params = f"{params}&{query_str}"
        conn.request(method="GET", url=f"{path}?{params}", headers=headers)
        response: http.client.HTTPResponse = conn.getresponse()
        data: str = response.read().decode()
        results.extend(json.loads(data))

        total_pages = int(response.headers.get("X-Total-Pages", 1))
        if page >= total_pages:
            break
        page += 1

    return results


def main() -> None:
    parsed_url: ParseResult = urlparse(url=GITLAB_INSTANCE)
    host: str = parsed_url.netloc
    conn = http.client.HTTPSConnection(host=host)

    print("Call all projects")
    projects_path = "/api/v4/projects"
    projects: List[Dict] = fetch_all_pages(conn=conn, path=projects_path)
    print(f"\n{repstr(string='=', length=30)}\n")

    for project in projects:
        project_id: int = project.get("id", 0)
        project_name: str = project.get("name", "N/A")

        pipelines_path: str = f"/api/v4/projects/{project_id}/pipelines"
        pipelines: List[Dict] = fetch_all_pages(
            conn=conn, path=pipelines_path, query_str="status=running"
        )

        for pipeline in pipelines:
            pipeline_id: int = pipeline.get("id", 0)
            pipeline_status: str = pipeline.get("status", "N/A")

            jobs_path: str = (
                f"/api/v4/projects/{project_id}/pipelines/{pipeline_id}/jobs"
            )
            jobs: List[Dict] = fetch_all_pages(
                conn=conn,
                path=jobs_path,
                query_str="scope[]=pending&scope[]=running",
            )

            for job in jobs:
                job_status: str = job.get("status", "N/A")
                job_runner: str = (job.get("runner", {}) or {}).get("description", "")

                print(f"Projekt: {project_name} (ID: {project_id})")
                print(f"  Pipeline ID: {pipeline_id}, Status: {pipeline_status}")
                print(
                    f"    Job ID: {job['id']}, Name: {job['name']}, Status: {job_status}, Runner: {job_runner}"
                )

                print(f"\n{repstr(string='=', length=5)}\n")

    conn.close()


if __name__ == "__main__":
    main()
