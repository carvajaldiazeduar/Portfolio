"""Notification adapters: SQS buffers the completion event, SNS delivers it.

Locally the SQS => SNS hop is drained by a consumer thread (in AWS the real
worker is the notify Lambda defined in the CDK stack).
"""

from __future__ import annotations

import json
import logging
import threading

log = logging.getLogger("streamvideo.notify")


class SqsSnsNotifier:
    """Pushes job events to SQS and delivers them through SNS."""

    def __init__(self, sqs, sns, queue_name: str, topic_name: str):
        self.sqs = sqs
        self.sns = sns
        self.queue_name = queue_name
        self.topic_name = topic_name
        self.queue_url: str | None = None
        self.topic_arn: str | None = None
        self.delivered = 0
        self._stop = threading.Event()
        self._thread: threading.Thread | None = None

    def ensure_resources(self) -> None:
        self.queue_url = self.sqs.create_queue(QueueName=self.queue_name)["QueueUrl"]
        self.topic_arn = self.sns.create_topic(Name=self.topic_name)["TopicArn"]

    def send(self, event: dict) -> None:
        if self.queue_url is None:
            raise RuntimeError("Notifier resources not initialized")
        self.sqs.send_message(
            QueueUrl=self.queue_url, MessageBody=json.dumps(event)
        )

    def consume_once(self, publish) -> int:
        if self.queue_url is None:
            raise RuntimeError("Notifier resources not initialized")
        response = self.sqs.receive_message(
            QueueUrl=self.queue_url, MaxNumberOfMessages=10,
            WaitTimeSeconds=1, VisibilityTimeout=30,
        )
        handled = 0
        for message in response.get("Messages", []):
            try:
                event = json.loads(message["Body"])
                publish(event)
                self.delivered += 1
            except Exception:
                log.exception("Failed to deliver notification")
            finally:
                self.sqs.delete_message(
                    QueueUrl=self.queue_url,
                    ReceiptHandle=message["ReceiptHandle"],
                )
                handled += 1
        return handled

    def start_consumer(self, publish) -> None:
        def loop() -> None:
            while not self._stop.is_set():
                try:
                    self.consume_once(publish)
                except Exception:
                    log.exception("Consumer poll failed")

        self._thread = threading.Thread(target=loop, daemon=True)
        self._thread.start()

    def stop(self) -> None:
        self._stop.set()
        if self._thread is not None:
            self._thread.join(timeout=5)


def publish_sns(sns, topic_arn: str) -> callable:
    def deliver(event: dict) -> None:
        sns.publish(
            TopicArn=topic_arn,
            Subject="video-ready",
            Message=json.dumps(event),
        )

    return deliver