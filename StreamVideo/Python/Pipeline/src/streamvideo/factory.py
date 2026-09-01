"""Wires every adapter from environment variables (driver pattern)."""

from __future__ import annotations

import logging

from . import config
from .analyze import LocalAnalyzer, RekognitionAnalyzer
from .aws import client
from .notify import SqsSnsNotifier
from .pipeline import VideoPipeline
from .repository import DynamoDbJobRepository
from .store import S3VideoStorage
from .transcode import StubTranscoder

log = logging.getLogger("streamvideo.factory")


def notifier() -> SqsSnsNotifier:
    return SqsSnsNotifier(
        client("sqs"),
        client("sns"),
        config.notify_queue(),
        config.notify_topic(),
    )


def build() -> VideoPipeline:
    storage = S3VideoStorage(
        client("s3"), config.input_bucket(), config.output_bucket()
    )
    repository = DynamoDbJobRepository(client("dynamodb"), config.jobs_table())

    transcoder_driver = config.transcoder_driver()
    if transcoder_driver != "stub":
        raise ValueError(f"Unsupported TRANSCODER driver: {transcoder_driver}")
    transcoder = StubTranscoder(storage)

    analyzer_driver = config.analyzer_driver()
    if analyzer_driver == "local":
        analyzer = LocalAnalyzer()
    elif analyzer_driver == "rekognition":
        analyzer = RekognitionAnalyzer(client("rekognition"))
    else:
        raise ValueError(f"Unsupported ANALYZER driver: {analyzer_driver}")

    log.info(
        "Pipeline: store=s3/%s->%s repo=dynamodb/%s transcoder=%s analyzer=%s",
        storage.input_bucket, storage.output_bucket, repository.table_name,
        transcoder_driver, analyzer_driver,
    )
    return VideoPipeline(storage, repository, transcoder, analyzer, notifier())