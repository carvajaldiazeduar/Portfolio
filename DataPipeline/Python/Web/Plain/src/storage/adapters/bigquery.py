import os
from storage.warehouse_adapter import DataWarehouseAdapter


class BigQuery(DataWarehouseAdapter):
    def __init__(self):
        self._client = None
        self.connect()

    def connect(self):
        if self._client is not None:
            return
        from google.cloud import bigquery
        project_id = os.getenv("BIGQUERY_PROJECT_ID", "")
        credentials_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "")
        self._client = bigquery.Client(project=project_id)

    def execute(self, query: str, params: tuple = None) -> list:
        self.connect()
        job_config = bigquery.QueryJobConfig()
        query_job = self._client.query(query, job_config=job_config)
        results = query_job.result()
        return [dict(row) for row in results]

    def bulk_insert(self, table: str, records: list) -> None:
        if not records:
            return
        self.connect()
        table_ref = self._client.dataset(os.getenv("BIGQUERY_DATASET", "etl")).table(table)
        errors = self._client.insert_rows_json(table_ref, records)
        if errors:
            raise RuntimeError(f"BigQuery insert errors: {errors}")

    def create_table(self, table: str, schema: dict) -> None:
        self.connect()
        from google.cloud import bigquery
        dataset_ref = self._client.dataset(os.getenv("BIGQUERY_DATASET", "etl"))
        table_ref = dataset_ref.table(table)
        schema_obj = [bigquery.SchemaField(name, dtype) for name, dtype in schema.items()]
        table = bigquery.Table(table_ref, schema=schema_obj)
        self._client.create_table(table, exists_ok=True)

    def list_tables(self) -> list:
        self.connect()
        dataset_ref = self._client.dataset(os.getenv("BIGQUERY_DATASET", "etl"))
        tables = self._client.list_tables(dataset_ref)
        return [t.table_id for t in tables]

    def close(self):
        self._client = None