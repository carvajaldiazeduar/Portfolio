"""SQS consumer: publishes the completion event to the SNS topic."""

import json
import os

import boto3

sns = boto3.client("sns")

TOPIC_ARN = os.environ["NOTIFY_TOPIC_ARN"]


def handler(event, context):
    for record in event["Records"]:
        message = json.loads(record["body"])
        sns.publish(
            TopicArn=TOPIC_ARN,
            Subject="video-ready",
            Message=record["body"],
        )
    return {"delivered": len(event["Records"])}