"""VideoStorage adapter (S3) behind a driver interface."""

from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Protocol

log = logging.getLogger("streamvideo.store")


@dataclass(frozen=True)
class VideoObject:
    bucket: str
    key: str
    size: int

    @property
    def name(self) -> str:
        return self.key.rsplit("/", 1)[-1]


class VideoStorage(Protocol):
    def ensure_storage(self) -> None: ...

    def exists(self, key: str) -> bool: ...

    def put(self, key: str, data: bytes) -> None: ...

    def get(self, key: str) -> bytes: ...

    def size_of(self, key: str) -> int: ...

    def metadata_of(self, key: str) -> dict: ...

    def copy(self, src_key: str, dst_key: str) -> None: ...

    def public_url(self, key: str) -> str: ...

    def list(self, prefix: str) -> list[str]: ...


class S3VideoStorage:
    """S3-backed implementation usable with real AWS or LocalStack."""

    def __init__(self, client, input_bucket: str, output_bucket: str):
        self.client = client
        self.input_bucket = input_bucket
        self.output_bucket = output_bucket

    def _bucket_exists(self, client, bucket: str) -> bool:
        try:
            client.head_bucket(Bucket=bucket)
            return True
        except Exception:
            return False

    def ensure_storage(self) -> None:
        for bucket in (self.input_bucket, self.output_bucket):
            if not self._bucket_exists(self.client, bucket):
                self.client.create_bucket(Bucket=bucket)
        self._enable_cors()

    def _enable_cors(self) -> None:
        # Browser (Vue web client) uploads to the input bucket; CORS is a demo
        # convenience and should not block real pipelines if it cannot be set.
        try:
            self.client.put_bucket_cors(
                Bucket=self.input_bucket,
                CORSConfiguration={
                    "CORSRules": [
                        {
                            "AllowedOrigins": ["*"],
                            "AllowedMethods": ["GET", "PUT", "POST", "HEAD"],
                            "AllowedHeaders": ["*"],
                            "ExposeHeaders": ["ETag"],
                            "MaxAgeSeconds": 3600,
                        }
                    ]
                },
            )
        except Exception as exc:  # pragma: no cover - environment dependent
            log.warning("Could not configure CORS on %s: %s", self.input_bucket, exc)

    def exists(self, key: str) -> bool:
        try:
            self.client.head_object(Bucket=self.input_bucket, Key=key)
            return True
        except Exception:
            return False

    def put(self, key: str, data: bytes) -> None:
        self.client.put_object(Bucket=self.input_bucket, Key=key, Body=data)

    def get(self, key: str) -> bytes:
        response = self.client.get_object(Bucket=self.input_bucket, Key=key)
        return response["Body"].read()

    def size_of(self, key: str) -> int:
        response = self.client.head_object(Bucket=self.input_bucket, Key=key)
        return response["ContentLength"]

    def metadata_of(self, key: str) -> dict:
        """User metadata (x-amz-meta-*) set on the object, if any."""
        response = self.client.head_object(Bucket=self.input_bucket, Key=key)
        return response.get("Metadata", {})

    def copy(self, src_key: str, dst_key: str) -> None:
        self.client.copy_object(
            Bucket=self.output_bucket,
            Key=dst_key,
            CopySource={"Bucket": self.input_bucket, "Key": src_key},
        )

    def public_url(self, key: str) -> str:
        return f"s3://{self.output_bucket}/{key}"

    def list(self, prefix: str) -> list[str]:
        keys: list[str] = []
        token = None
        while True:
            params: dict = {"Bucket": self.input_bucket, "Prefix": prefix}
            if token:
                params["ContinuationToken"] = token
            response = self.client.list_objects_v2(**params)
            keys.extend(item["Key"] for item in response.get("Contents", []))
            if not response.get("IsTruncated"):
                break
            token = response.get("NextContinuationToken")
        return keys