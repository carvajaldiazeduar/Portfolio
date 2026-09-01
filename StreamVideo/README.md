# 🎥 StreamVideo — Serverless video processing & analytics

Real-time video ingestion, transcoding and content-moderation pipeline built on **AWS serverless** services (S3, EventBridge, Step Functions, Lambda, Batch/ECS Fargate, Rekognition, DynamoDB, SQS, SNS, IAM), implemented with **Python** and shipped as **AWS CDK** infrastructure-as-code. The full async flow is emulated locally against **LocalStack** with the same driver pattern used across the portfolio.

| Component | In the cloud (CDK) | Locally (LocalStack) |
|---|---|---|
| Object storage | S3 (input + output) | S3 via LocalStack |
| Orchestration | Step Functions (metadata → parallel[transcode, analyze] → finalize → notify) | `VideoPipeline` + runner |
| Job state | DynamoDB (`streamvideo-jobs`) | DynamoDB via LocalStack |
| Transcoding | AWS Batch / ECS Fargate running `ffmpeg` | `StubTranscoder` (copy to 1080p/720p/480p) |
| Content analysis | Lambda + Amazon Rekognition label detection | `LocalAnalyzer` (deterministic labels) |
| Decoupling | SQS (`streamvideo-notifications`) | SQS via LocalStack |
| Delivery | Lambda → SNS topic | SQS → SNS consumer thread |

---

## 🏗️ Architecture

```
                        +-------------------- AWS (CDK) --------------------+
                        |                                                    |
  S3 (raw/* upload)     |    EventBridge (Object Created)                    |
        |               |         |                                          |
        v               |         v                                          |
  S3 Input bucket       |   Step Functions: VideoPipeline                    |
        +-------------> |   ├── Metadata (Lambda) ──► DynamoDB (PROCESSING)  |
                        |   ├── Parallel ────────────────────────────────────┘
                        |   │   ├── Transcode (AWS Batch / Fargate + ffmpeg) |
                        |   │   └── Analyze (Lambda + Rekognition labels)    |
                        |   ├── Finalize (Lambda) ──► DynamoDB (COMPLETED)   |
                        |   └── Publish (SQS sendMessage)                    |
                        |              |                                     |
                        |              v                                     |
                        |   SQS queue ──► Notify Lambda ──► SNS topic (subs) |
                        +----------------------------------------------------+
```

The **local pipeline** (`Python/Pipeline`) mirrors exactly these steps against LocalStack so the whole flow is verifiable end-to-end without an AWS account:

```
S3 (upload) → VideoPipeline.process() →
    DynamoDB (PROCESSING) → transcode (stub) / analyze (local) →
    DynamoDB (COMPLETED) → SQS → consumer → SNS
```

---

## 🗂️ Repository layout

```
StreamVideo/
├── Python/
│   └── Pipeline/                    # Local emulated pipeline (runs against LocalStack)
│       ├── src/streamvideo/
│       │   ├── config.py            # env-driven configuration
│       │   ├── aws.py               # boto3 client factory (AWS_ENDPOINT_URL-aware, S3 path-style)
│       │   ├── store.py             # VideoStorage adapter  (S3)
│       │   ├── repository.py        # JobRepository adapter (DynamoDB)
│       │   ├── transcode.py         # Transcoder adapter    (stub → ffmpeg in AWS)
│       │   ├── analyze.py           # Analyzer adapter       (local → Rekognition)
│       │   ├── notify.py            # SQS → SNS notifier + consumer
│       │   ├── pipeline.py          # VideoPipeline orchestration
│       │   ├── factory.py           # driver wiring from env
│       │   └── runner.py            # CLI: init | demo | worker | ingest
│       ├── tests/                   # pytest + moto
│       ├── Dockerfile
│       ├── docker-compose.yml       # LocalStack 3.1.0 + pipeline demo
│       └── requirements[.dev].txt
└── Cdk/                             # AWS CDK (Python) — real deployment
    ├── app.py / cdk.json
    ├── streamvideo_stack.py         # the whole AWS infrastructure
    ├── lambdas/                     # metadata / analyze / finalize / notify
    └── requirements.txt
```

---

## 🚀 Quick Start (local, no AWS account)

```bash
cd StreamVideo/Python/Pipeline
podman compose up --build pipeline
```

This starts LocalStack (`4566`) and runs the `demo` command, which:

1. Creates buckets, the DynamoDB table, the SQS queue and the SNS topic.
2. Uploads a sample video to `s3://streamvideo-input/raw/launch-demo.mp4`.
3. Runs the full pipeline (status `PROCESSING → COMPLETED`).
4. Drains SQS into SNS and prints the notification.

Expected output ends with `Notifications delivered via SNS: 1`.

### Manual CLI

```bash
# create backend resources
docker run --rm -v "$PWD":/app -w /app -e AWS_ENDPOINT_URL=http://localhost:4566 \
  -e AWS_ACCESS_KEY_ID=mock_key -e AWS_SECRET_ACCESS_KEY=mock_secret \
  python:3.12-slim python -m streamvideo.runner init
```

Or run the tests:

```bash
cd StreamVideo/Python/Pipeline
python -m pytest            # 5 tests, uses moto (no LocalStack needed)
```

---

## 🌩️ Deploying to AWS (CDK)

```bash
cd StreamVideo/Cdk
python -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt
cdk bootstrap
cdk deploy --context account=123456789012 --context region=us-east-1
```

The stack creates: S3 buckets, DynamoDB, SQS, SNS, 4 Lambdas, AWS Batch compute environment + job queue + ffmpeg job definition, the Step Functions state machine, an IAM role for EventBridge → Step Functions, and an EventBridge rule that triggers on `raw/*` object creation.

Upload a video to start the flow:

```bash
aws s3 cp demo.mp4 s3://streamvideo-input/raw/demo.mp4
```

Watch it complete:

```bash
aws dynamodb get-item --table-name streamvideo-jobs \
  --key '{"video_key":{"S":"raw/demo.mp4"}}' --output json
```

---

## 🔌 Adapter pattern & environment variables

All adapters are selected by env (same factory pattern as the rest of the portfolio):

| Variable | Values | Default |
|---|---|---|
| `ANALYZER` | `local` \| `rekognition` | `local` |
| `TRANSCODER` | `stub` (ffmpeg runs in AWS Batch) | `stub` |
| `INPUT_BUCKET` | bucket name | `streamvideo-input` |
| `OUTPUT_BUCKET` | bucket name | `streamvideo-output` |
| `JOBS_TABLE` | DynamoDB table | `streamvideo-jobs` |
| `NOTIFY_QUEUE` | SQS queue | `streamvideo-notifications` |
| `NOTIFY_TOPIC` | SNS topic | `streamvideo-notifications` |
| `AWS_ENDPOINT_URL` | LocalStack endpoint | *(empty → real AWS)* |
| `AWS_REGION` / `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | credentials | `us-east-1` / mock |

> `AWS_ENDPOINT_URL` empty means the pipeline talks to real AWS; set it to `http://localhost:4566` (or the LocalStack compose service name) to emulate.

---

## 🧪 Tests (local)

| Test | Coverage |
|---|---|
| `test_demo_job_reaches_completed` | Full pipeline on moto: object uploaded → status `COMPLETED`, labels + 3 resolutions, metadata. |
| `test_failed_job_is_recorded` | Transcoder failure → job status `FAILED`. |
| `test_missing_video_raises` | Non-existent object → `FileNotFoundError`. |
| `test_completion_event_is_buffered_in_sqs` | Completion event lands in SQS and is drained into SNS. |
| `test_event_has_completion_payload` | Event carries `status`/`video_key`. |

## 📄 License

MIT — see [LICENSE](../LICENSE) in the repository root.
