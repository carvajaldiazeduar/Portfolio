"""Content analysis adapters: Amazon Rekognition in the cloud, deterministic stub locally."""

from __future__ import annotations

import time
from typing import Protocol


class Analyzer(Protocol):
    def analyze(self, video_key: str, name: str) -> list[str]:
        """Return a list of detected labels."""


class LocalAnalyzer:
    """Deterministic labels used by the emulated pipeline (no AI dependency)."""

    def analyze(self, video_key: str, name: str) -> list[str]:
        return ["person", "vehicle", "outdoor"]


class RekognitionAnalyzer:
    """Runs Amazon Rekognition Video label detection (start + poll)."""

    def __init__(self, client, poll_seconds: int = 2, max_attempts: int = 120):
        self.client = client
        self.poll_seconds = poll_seconds
        self.max_attempts = max_attempts

    def _start(self, video_key: str) -> str:
        from . import config

        kwargs = {
            "Video": {"S3Object": {"Bucket": config.input_bucket(), "Name": video_key}},
        }
        response = self.client.start_label_detection(**kwargs)
        return response["JobId"]

    def _poll(self, job_id: str) -> list[str]:
        for _ in range(self.max_attempts):
            response = self.client.get_label_detection(JobId=job_id)
            status = response["JobStatus"]
            if status == "SUCCEEDED":
                labels = {
                    label["Label"]["Name"]
                    for label in response.get("Labels", [])
                }
                return sorted(labels)
            if status == "FAILED":
                raise RuntimeError("Rekognition job failed: %s" % response.get("StatusMessage"))
            time.sleep(self.poll_seconds)
        raise TimeoutError("Timed out waiting for Rekognition job %s" % job_id)

    def analyze(self, video_key: str, name: str) -> list[str]:
        job_id = self._start(video_key)
        return self._poll(job_id)