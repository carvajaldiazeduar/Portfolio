"""Step Functions: Amazon Rekognition label detection (async start + poll)."""

import time

import boto3

rekognition = boto3.client("rekognition")


def handler(event, context):
    bucket = event["bucket"]
    video_key = event["video_key"]

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