"""Job state repository (DynamoDB) behind a driver interface."""

from __future__ import annotations

import json
import time
from typing import Protocol

STATUS_PROCESSING = "PROCESSING"
STATUS_COMPLETED = "COMPLETED"
STATUS_FAILED = "FAILED"


class JobRepository(Protocol):
    def ensure_table(self) -> None: ...

    def create_job(self, video_key: str) -> None: ...

    def update_job(self, video_key: str, **fields) -> None: ...

    def get_job(self, video_key: str) -> dict | None: ...


class DynamoDbJobRepository:
    """DynamoDB implementation; single global index keyed on the video key."""

    def __init__(self, client, table_name: str):
        self.client = client
        self.table_name = table_name

    def _attr(self, fields: dict) -> dict:
        attributes = {}
        for key, value in fields.items():
            if isinstance(value, bool):
                attributes[key] = {"BOOL": value}
            elif isinstance(value, (int, float)):
                attributes[key] = {"N": str(value)}
            elif isinstance(value, (list, dict)):
                attributes[key] = {"S": json.dumps(value)}
            else:
                attributes[key] = {"S": str(value)}
        return attributes

    def ensure_table(self) -> None:
        try:
            self.client.describe_table(TableName=self.table_name)
        except self.client.exceptions.ResourceNotFoundException:
            self.client.create_table(
                TableName=self.table_name,
                KeySchema=[{"AttributeName": "video_key", "KeyType": "HASH"}],
                AttributeDefinitions=[
                    {"AttributeName": "video_key", "AttributeType": "S"}
                ],
                BillingMode="PAY_PER_REQUEST",
            )
            self.client.get_waiter("table_exists").wait(
                TableName=self.table_name, WaiterConfig={"Delay": 1, "MaxAttempts": 20}
            )

    def create_job(self, video_key: str) -> None:
        request = {
            "TableName": self.table_name,
            "Item": self._attr(
                {
                    "video_key": video_key,
                    "status": STATUS_PROCESSING,
                    "created_at": int(time.time()),
                }
            ),
        }
        self.client.put_item(**request)

    def update_job(self, video_key: str, **fields) -> None:
        fields.setdefault("updated_at", int(time.time()))
        names = {f"#{key}": key for key in fields}
        values = {f":{key}": list(self._attr({key: value}).values())[0] for key, value in fields.items()}
        expression = ", ".join(f"#{key} = :{key}" for key in fields)
        self.client.update_item(
            TableName=self.table_name,
            Key={"video_key": {"S": video_key}},
            UpdateExpression=f"SET {expression}",
            ExpressionAttributeNames=names,
            ExpressionAttributeValues=values,
        )

    def get_job(self, video_key: str) -> dict | None:
        response = self.client.get_item(
            TableName=self.table_name, Key={"video_key": {"S": video_key}}
        )
        item = response.get("Item")
        if item is None:
            return None
        return {key: self._from_attr(attr) for key, attr in item.items()}

    def _from_attr(self, attr: dict):
        if "S" in attr:
            value = attr["S"]
            if value[:1] in ("[", "{"):
                try:
                    return json.loads(value)
                except ValueError:
                    return value
            return value
        if "N" in attr:
            return attr["N"]
        if "BOOL" in attr:
            return attr["BOOL"]
        if "SS" in attr:
            return attr["SS"]
        if "NS" in attr:
            return attr["NS"]
        return attr