"""Step Functions: consolidates outputs, marks the job COMPLETED and emits the event."""

import os
import time

import boto3

dynamodb = boto3.resource("dynamodb")

TABLE = os.environ["JOBS_TABLE"]
OUTPUT_BUCKET = os.environ["OUTPUT_BUCKET"]
RESOLUTIONS = ("1080p", "720p", "480p")


def handler(event, context):
    table = dynamodb.Table(TABLE)
    labels = event.get("labels", [])

    key = event["video_key"]
    outputs = {
        resolution: f"s3://{OUTPUT_BUCKET}/transcoded/{resolution}/{key}"
        for resolution in RESOLUTIONS
    }

    table.update_item(
        Key={"video_key": key},
        UpdateExpression=(
            "SET #status = :status, #labels = :labels, #outputs = :outputs, "
            "#updated_at = :updated_at, #bucket = :bucket, #metadata = :metadata"
        ),
        ExpressionAttributeNames={
            "#status": "status",
            "#labels": "labels",
            "#outputs": "outputs",
            "#updated_at": "updated_at",
            "#bucket": "bucket",
            "#metadata": "metadata",
        },
        ExpressionAttributeValues={
            ":status": "COMPLETED",
            ":labels": labels,
            ":outputs": outputs,
            ":updated_at": int(time.time()),
            ":bucket": event["bucket"],
            ":metadata": event.get("metadata", {}),
        },
    )

    return {
        "video_key": key,
        "status": "COMPLETED",
        "labels": labels,
        "outputs": outputs,
        "metadata": event.get("metadata", {}),
    }