"""VideoPipeline: the orchestration flow shared by the local runner and AWS."""

from __future__ import annotations

import logging
import os

from .repository import STATUS_COMPLETED, STATUS_FAILED, STATUS_PROCESSING

log = logging.getLogger("streamvideo.pipeline")


def estimate_metadata(video_key: str, size: int) -> dict:
    """Lightweight metadata approximation used locally; the real metadata extractor
    is the `metadata` Lambda in the CDK stack."""
    extension = os.path.splitext(video_key)[1].lower().lstrip(".")
    seconds = max(1, size // (2 * 1024 * 1024))
    return {
        "key": video_key,
        "container": extension or "mp4",
        "duration_sec": seconds,
        "size_bytes": size,
    }


class VideoPipeline:
    def __init__(self, storage, repository, transcoder, analyzer, notifier):
        self.storage = storage
        self.repository = repository
        self.transcoder = transcoder
        self.analyzer = analyzer
        self.notifier = notifier

    def init_resources(self) -> None:
        self.storage.ensure_storage()
        self.repository.ensure_table()
        self.notifier.ensure_resources()

    def process(self, video_key: str) -> dict:
        if not self.storage.exists(video_key):
            raise FileNotFoundError("No video object %r in storage" % video_key)

        self.repository.create_job(video_key)
        try:
            log.info("Processing %s", video_key)
            size = self.storage.size_of(video_key)
            data = self.storage.get(video_key)
            name = video_key.rsplit("/", 1)[-1]

            outputs = self.transcoder.transcode(video_key, name, data)
            labels = self.analyzer.analyze(video_key, name)

            urls = {resolution: self.storage.public_url(key) for resolution, key in outputs.items()}
            metadata = estimate_metadata(video_key, size)

            self.repository.update_job(
                video_key,
                status=STATUS_COMPLETED,
                metadata=metadata,
                outputs=urls,
                labels=labels,
            )

            event = {
                "video_key": video_key,
                "status": STATUS_COMPLETED,
                "labels": labels,
                "outputs": urls,
            }
            self.notifier.send(event)
            log.info("Finished %s", video_key)
            return self.repository.get_job(video_key)
        except Exception:
            self.repository.update_job(video_key, status=STATUS_FAILED)
            raise