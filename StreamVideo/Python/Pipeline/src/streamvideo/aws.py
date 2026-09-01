"""boto3 client factory aware of AWS_ENDPOINT_URL (LocalStack / AWS)."""

from __future__ import annotations

import boto3

from . import config


def client(service: str):
    kwargs = {"region_name": config.region()}
    endpoint = config.endpoint_url()
    if endpoint:
        kwargs["endpoint_url"] = endpoint
        if service == "s3":
            import botocore

            kwargs["config"] = botocore.config.Config(
                s3={"addressing_style": "path"}
            )
    access_key = config.env("AWS_ACCESS_KEY_ID")
    secret_key = config.env("AWS_SECRET_ACCESS_KEY")
    if access_key:
        kwargs["aws_access_key_id"] = access_key
    if secret_key:
        kwargs["aws_secret_access_key"] = secret_key
    return boto3.client(service, **kwargs)