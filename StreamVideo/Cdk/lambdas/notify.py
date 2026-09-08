"""SQS consumer: publishes the completion event to the SNS topic.

Signs each message with an HMAC signing key pulled from AWS Secrets Manager
at runtime, so subscribers can verify the payload came from this pipeline.
"""

import hashlib
import hmac
import json
import os

import boto3

sns = boto3.client("sns")

TOPIC_ARN = os.environ["NOTIFY_TOPIC_ARN"]
NOTIFY_SECRET_ARN = os.environ["NOTIFY_SECRET_ARN"]


def _signing_key() -> bytes:
    client = boto3.client("secretsmanager")
    value = client.get_secret_value(SecretId=NOTIFY_SECRET_ARN)["SecretString"]
    return json.loads(value).get("hmac_signing_key", "").encode("utf-8")


def _sign(key: bytes, body: bytes) -> str:
    return hmac.new(key, body, hashlib.sha256).hexdigest()


def handler(event, context):
    key = _signing_key()
    for record in event["Records"]:
        body = record["body"].encode("utf-8")
        signature = _sign(key, body)
        sns.publish(
            TopicArn=TOPIC_ARN,
            Subject="video-ready",
            Message=record["body"],
            MessageAttributes={
                "x-signature": {
                    "DataType": "String",
                    "StringValue": signature,
                }
            },
        )
    return {"delivered": len(event["Records"])}