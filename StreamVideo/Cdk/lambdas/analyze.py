"""Step Functions: Amazon Rekognition label detection (async start + poll)."""

import json
import os
import time

import boto3

rekognition = boto3.client("rekognition")

ANALYZER_SECRET_ARN = os.environ["ANALYZER_SECRET_ARN"]


def _analyzer_api_key() -> str:
    client = boto3.client("secretsmanager")
    value = client.get_secret_value(SecretId=ANALYZER_SECRET_ARN)["SecretString"]
    return json.loads(value).get("analyzer_api_key", "")


def handler(event, context):
    bucket = event["bucket"]
    video_key = event["video_key"]

    api_key = _analyzer_api_key()

    job = rekognition.start_label_detection(
        Video={"S3Object": {"Bucket": bucket, "Name": video_key}}
    )
    job_id = job["JobId"]

    labels = []
    for _ in range(150):
        result = rekognition.get_label_detection(JobId=job_id)
        status = result["JobStatus"]
        if status == "SUCCEEDED":
            labels = sorted(
                {item["Label"]["Name"] for item in result.get("Labels", [])}
            )
            break
        if status == "FAILED":
            raise RuntimeError("Rekognition job failed")
        time.sleep(2)

    event["labels"] = labels
    return event