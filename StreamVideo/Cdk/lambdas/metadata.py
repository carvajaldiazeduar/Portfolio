"""Step Functions: extracts metadata and marks the job as PROCESSING."""

import json
import os
import time

import boto3

s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")

TABLE = os.environ["JOBS_TABLE"]


def handler(event, context):
    bucket = event["detail"]["bucket"]["name"]
    key = event["detail"]["object"]["key"]

    head = s3.head_object(Bucket=bucket, Key=key)
    size = head.get("ContentLength", 0)
    extension = key.rsplit(".", 1)[-1].lower() if "." in key else "mp4"

    table = dynamodb.Table(TABLE)
    table.put_item(
        Item={
            "video_key": key,
            "status": "PROCESSING",
            "created_at": int(time.time()),
            "bucket": bucket,
            "metadata": {
                "key": key,
                "container": extension,
                "size_bytes": size,
            },
        }
    )

    return {
        "bucket": bucket,
        "video_key": key,
        "metadata": {"key": key, "container": extension, "size_bytes": size},
    }


if __name__ == "__main__":
    print(json.dumps(handler({"detail": {"bucket": {"name": "x"}, "object": {"key": "y.mp4"}}}, None)))