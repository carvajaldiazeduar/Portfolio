"""Environment-driven configuration shared by every adapter."""

from __future__ import annotations

import os


def env(name: str, default: str | None = None) -> str | None:
    return os.environ.get(name, default)


def env_str(name: str, default: str) -> str:
    value = os.environ.get(name)
    return value if value not in (None, "") else default


def env_int(name: str, default: int) -> int:
    value = os.environ.get(name)
    return int(value) if value not in (None, "") else default


def endpoint_url() -> str | None:
    value = os.environ.get("AWS_ENDPOINT_URL")
    return value if value not in (None, "") else None


def region() -> str:
    return env_str("AWS_REGION", "us-east-1")


def input_bucket() -> str:
    return env_str("INPUT_BUCKET", "streamvideo-input")


def output_bucket() -> str:
    return env_str("OUTPUT_BUCKET", "streamvideo-output")


def jobs_table() -> str:
    return env_str("JOBS_TABLE", "streamvideo-jobs")


def notify_queue() -> str:
    return env_str("NOTIFY_QUEUE", "streamvideo-notifications")


def notify_topic() -> str:
    return env_str("NOTIFY_TOPIC", "streamvideo-notifications")


def analyzer_driver() -> str:
    return env_str("ANALYZER", "local")


def transcoder_driver() -> str:
    return env_str("TRANSCODER", "stub")