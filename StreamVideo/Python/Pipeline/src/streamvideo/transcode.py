"""Transcoding adapters: real AWS runs ffmpeg in Batch, local stubs copy the stream."""

from __future__ import annotations

from typing import Protocol

RESOLUTIONS = ("1080p", "720p", "480p")


class Transcoder(Protocol):
    def transcode(self, video_key: str, name: str, data: bytes) -> dict[str, str]:
        """Return a mapping {resolution: output object key}."""


class StubTranscoder:
    """Emulates the heavy transcode step locally by re-uploading the stream
    once per target resolution. The real ffmpeg job lives in AWS Batch
    (see the CDK stack)."""

    def __init__(self, storage):
        self.storage = storage

    def transcode(self, video_key: str, name: str, data: bytes) -> dict[str, str]:
        outputs = {}
        for resolution in RESOLUTIONS:
            destination = f"transcoded/{resolution}/{name}"
            self.storage.copy(video_key, destination)
            outputs[resolution] = destination
        return outputs