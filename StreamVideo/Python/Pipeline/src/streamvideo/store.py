"""VideoStorage adapter (S3) behind a driver interface."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol


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

    def copy(self, src_key: str, dst_key: str) -> None: ...

    def public_url(self, key: str) -> str: ...


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

    def copy(self, src_key: str, dst_key: str) -> None:
        self.client.copy_object(
            Bucket=self.output_bucket,
            Key=dst_key,
            CopySource={"Bucket": self.input_bucket, "Key": src_key},
        )

    def public_url(self, key: str) -> str:
        return f"s3://{self.output_bucket}/{key}"