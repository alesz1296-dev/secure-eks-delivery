"""Minimal API used to exercise the platform and security workflow."""

from itertools import count
from os import getenv

from fastapi import FastAPI, status
from pydantic import BaseModel, Field

APP_VERSION = getenv("APP_VERSION", "dev")

app = FastAPI(
    title="Secure EKS Delivery Lab API",
    version=APP_VERSION,
    docs_url="/docs",
    redoc_url=None,
)


class TaskCreate(BaseModel):
    title: str = Field(min_length=1, max_length=120)


class Task(BaseModel):
    id: int
    title: str
    completed: bool = False


task_ids = count(start=1)
tasks: list[Task] = []


@app.get("/", tags=["service"])
def service_info() -> dict[str, str]:
    return {"service": "secure-eks-delivery", "version": APP_VERSION}


@app.get("/health/live", tags=["health"])
def liveness() -> dict[str, str]:
    """Liveness endpoint: the process is able to serve requests."""
    return {"status": "ok"}


@app.get("/health/ready", tags=["health"])
def readiness() -> dict[str, str]:
    """Readiness endpoint: dependencies would be checked here when added."""
    return {"status": "ready"}


@app.get("/api/tasks", response_model=list[Task], tags=["tasks"])
def list_tasks() -> list[Task]:
    return tasks


@app.post(
    "/api/tasks",
    response_model=Task,
    status_code=status.HTTP_201_CREATED,
    tags=["tasks"],
)
def create_task(task: TaskCreate) -> Task:
    new_task = Task(id=next(task_ids), title=task.title)
    tasks.append(new_task)
    return new_task

