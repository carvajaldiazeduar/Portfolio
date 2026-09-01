from __future__ import annotations

import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

import pytest

from streamvideo import config


@pytest.fixture(autouse=True)
def aws_env(monkeypatch):
    monkeypatch.setenv("AWS_REGION", "us-east-1")
    monkeypatch.setenv("AWS_ACCESS_KEY_ID", "testing")
    monkeypatch.setenv("AWS_SECRET_ACCESS_KEY", "testing")
    if os.environ.get("STREAMVIDEO_KEEP_ENDPOINT"):
        yield config.endpoint_url()
    else:
        monkeypatch.delenv("AWS_ENDPOINT_URL", raising=False)
        yield None


@pytest.fixture()
def mock_aws():
    from moto import mock_aws

    with mock_aws():
        yield


@pytest.fixture()
def clients():
    from streamvideo.aws import client

    return {
        "s3": client("s3"),
        "dynamodb": client("dynamodb"),
        "sqs": client("sqs"),
        "sns": client("sns"),
    }


@pytest.fixture()
def pipeline(mock_aws, clients):
    from streamvideo.analyze import LocalAnalyzer
    from streamvideo.notify import SqsSnsNotifier
    from streamvideo.pipeline import VideoPipeline
    from streamvideo.repository import DynamoDbJobRepository
    from streamvideo.store import S3VideoStorage
    from streamvideo.transcode import StubTranscoder

    storage = S3VideoStorage(
        clients["s3"], "streamvideo-input", "streamvideo-output"
    )
    repository = DynamoDbJobRepository(clients["dynamodb"], "streamvideo-jobs")
    notifier = SqsSnsNotifier(
        clients["sqs"], clients["sns"],
        "streamvideo-notifications", "streamvideo-notifications",
    )
    instance = VideoPipeline(
        storage, repository, StubTranscoder(storage), LocalAnalyzer(), notifier
    )
    instance.init_resources()
    return instance


@pytest.fixture()
def sample_video() -> bytes:
    payload = bytearray()
    for index in range(32):
        payload.extend((b"frame-%04d-" % index) * 64)
    return bytes(payload)