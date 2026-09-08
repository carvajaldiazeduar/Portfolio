"""Command line entry points for the emulated pipeline.

Commands:
  init       create backend resources (buckets, table, queue, topic)
  demo       upload a sample video, run the pipeline and drain notifications
  worker     keep draining SQS notifications into SNS
  ingest     upload <file> and process it
"""

from __future__ import annotations

import argparse
import logging
import sys
import time

from . import config
from .factory import build
from .notify import publish_sns

SAMPLE_VIDEO_KEY = "raw/launch-demo.mp4"


def _init_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="streamvideo")
    parser.add_argument("command", choices=["init", "demo", "worker", "ingest", "watch"])
    parser.add_argument("file", nargs="?", default=None, help="file for ingest")
    return parser


def _sample_video() -> bytes:
    payload = bytearray()
    for index in range(256):
        payload.extend((b"frame-%04d-" % index) * 128)
    return bytes(payload)


def cmd_init() -> None:
    pipeline = build()
    pipeline.init_resources()
    print("Resources ready: " + config.input_bucket())


def cmd_demo() -> None:
    pipeline = build()
    pipeline.init_resources()
    video = _sample_video()
    pipeline.storage.put(SAMPLE_VIDEO_KEY, video)
    print("Uploaded sample video -> s3://%s/%s (%d bytes)" %
          (config.input_bucket(), SAMPLE_VIDEO_KEY, len(video)))

    job = pipeline.process(SAMPLE_VIDEO_KEY)
    print("Job finished:")
    print(job)

    deliver = publish_sns(
        client_sns(), pipeline.notifier.topic_arn
    )
    for _ in range(5):
        handled = pipeline.notifier.consume_once(deliver)
        if handled == 0 and pipeline.notifier.delivered > 0:
            break
        time.sleep(0.5)
    print("Notifications delivered via SNS:", pipeline.notifier.delivered)


def cmd_worker() -> None:
    from .aws import client as aws_client

    pipeline = build()
    pipeline.init_resources()
    deliver = publish_sns(aws_client("sns"), pipeline.notifier.topic_arn)
    print("Worker consuming %s -> topic %s (Ctrl+C to stop)" %
          (pipeline.notifier.queue_name, pipeline.notifier.topic_name))
    pipeline.notifier.start_consumer(deliver)
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        pipeline.notifier.stop()


def cmd_watch() -> None:
    from .repository import STATUS_COMPLETED, STATUS_FAILED

    pipeline = build()
    pipeline.init_resources()
    deliver = publish_sns(client_sns(), pipeline.notifier.topic_arn)
    print("Watching s3://%s/raw/ for new videos (Ctrl+C to stop)" % config.input_bucket())
    try:
        while True:
            processed_any = False
            for key in pipeline.storage.list("raw/"):
                job = pipeline.repository.get_job(key)
                if job is None or job.get("status") not in (STATUS_COMPLETED, STATUS_FAILED):
                    result = pipeline.process(key)
                    print("Processed", key, "->", result)
                    processed_any = True
            handled = pipeline.notifier.consume_once(deliver)
            if not processed_any and handled == 0:
                time.sleep(2)
    except KeyboardInterrupt:
        pass


def cmd_ingest(file_path: str) -> None:
    pipeline = build()
    pipeline.init_resources()
    key = "ingested/" + file_path.split("/")[-1]
    with open(file_path, "rb") as handle:
        pipeline.storage.put(key, handle.read())
    print("Uploaded -> s3://%s/%s" % (config.input_bucket(), key))
    print(pipeline.process(key))


def client_sns():
    from .aws import client

    return client("sns")


def main(argv=None) -> int:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s: %(message)s")
    args = _init_parser().parse_args(argv)
    if args.command == "init":
        cmd_init()
    elif args.command == "demo":
        cmd_demo()
    elif args.command == "worker":
        cmd_worker()
    elif args.command == "watch":
        cmd_watch()
    elif args.command == "ingest":
        if not args.file:
            print("ingest requires <file>", file=sys.stderr)
            return 2
        cmd_ingest(args.file)
    return 0


if __name__ == "__main__":
    sys.exit(main())