from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_service_info() -> None:
    response = client.get("/")

    assert response.status_code == 200
    assert response.json()["service"] == "secure-eks-delivery"


def test_health_endpoints() -> None:
    assert client.get("/health/live").json() == {"status": "ok"}
    assert client.get("/health/ready").json() == {"status": "ready"}


def test_metrics_endpoint() -> None:
    response = client.get("/metrics")

    assert response.status_code == 200
    assert "http_requests_total" in response.text
    assert "http_request_duration_seconds" in response.text


def test_create_task() -> None:
    response = client.post("/api/tasks", json={"title": "Deploy securely"})

    assert response.status_code == 201
    assert response.json()["title"] == "Deploy securely"
    assert response.json()["completed"] is False


def test_rejects_blank_task_title() -> None:
    response = client.post("/api/tasks", json={"title": ""})

    assert response.status_code == 422
