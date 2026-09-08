# 🎥 StreamVideo — Serverless video processing & analytics

Real-time video ingestion, transcoding and content-moderation pipeline built on **AWS serverless** services (S3, EventBridge, Step Functions, Lambda, Batch/ECS Fargate, Rekognition, DynamoDB, SQS, SNS, Secrets Manager, IAM), implemented in **Python** and **.NET 10 (C#)**, and shipped as **AWS CDK** infrastructure-as-code. The full async flow is emulated locally against **LocalStack** using the same adapter/factory pattern used across the portfolio.

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

This flow is mirrored 1:1 by the local emulation (`Python/Pipeline` against LocalStack), so the whole pipeline is verifiable end-to-end without an AWS account.

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
│       │   └── runner.py            # CLI: init | demo | worker | watch | ingest
│       ├── tests/                   # pytest + moto
│       ├── Dockerfile
│       ├── docker-compose.yml       # LocalStack 3.1.0 + pipeline watcher + web server (:5006)
│       └── requirements[.dev].txt
├── DotNet/
│   └── Pipeline/                    # .NET 10 port of the local pipeline (AWSSDK + LocalStack)
│       ├── src/
│       │   ├── StreamVideo.csproj   # net10.0 console app (AWSSDK S3/DynamoDB/SQS/SNS/Rekognition)
│       │   ├── Config.cs            # env-driven configuration
│       │   ├── AwsClientFactory.cs  # AWSSDK client factory (AWS_ENDPOINT_URL-aware, path-style)
│       │   ├── Storage.cs           # IVideoStorage + S3VideoStorage
│       │   ├── Repository.cs        # IJobRepository + DynamoDbJobRepository
│       │   ├── Transcoding.cs       # ITranscoder + StubTranscoder
│       │   ├── Analysis.cs          # IAnalyzer + LocalAnalyzer + RekognitionAnalyzer
│       │   ├── Notifications.cs     # INotifier + SqsSnsNotifier + SnsPublisher
│       │   ├── VideoPipeline.cs     # VideoPipeline orchestration
│       │   ├── Factory.cs           # driver wiring from env
│       │   ├── Program.cs           # CLI: init | demo | worker | watch | ingest
│       │   └── Testing/             # in-memory doubles (tests, no AWS needed)
│       │   └── tests/               # xunit (mirrors pytest suite)
│       ├── Dockerfile
│       └── docker-compose.yml       # LocalStack 3.1.0 + pipeline watcher + web server (:5006)
├── Web/
│   └── index.html                   # Vue 3 + AWS SDK v3 from CDN (no build): drag&drop uploads; lists extracted data (status, duration, resolutions, labels)
└── Cdk/                             # AWS CDK (Python) — real deployment
    ├── app.py / cdk.json
    ├── streamvideo_stack.py         # the whole AWS infrastructure
    ├── lambdas/                     # metadata / analyze / finalize / notify
    └── requirements.txt
```

---

## 🚀 How to use it (local — no AWS account)

> Required: [Podman](https://podman.io) (or Docker). Everything runs in containers — no Python/.NET install needed.

### 1. Start LocalStack + the pipeline watcher

```bash
cd StreamVideo/Python/Pipeline
podman compose up --build pipeline
```

This starts LocalStack on `http://localhost:4566`, creates the buckets/table/queue/topic and runs a **watcher**: every video that lands under `raw/` (dragged into the web page or uploaded any other way) is processed automatically — no manual step. The watcher stays in the foreground (Ctrl+C to stop; or use `up -d` to run it in the background — LocalStack and the web server keep running).

To also see the built-in sample video demo, run in a second terminal (optional):

```bash
podman compose run --rm pipeline demo
```

That prints `Job finished: {... 'labels': ['person', 'vehicle', 'outdoor'], 'status': 'COMPLETED' ...}` and `Notifications delivered via SNS: 1`.

### 2. Process your own video

With LocalStack still running, point the CLI at your local file. It uploads it to `ingested/` and processes it right away:

```bash
cd StreamVideo/Python/Pipeline
podman compose run --rm -v "$PWD:/uploads" pipeline ingest /uploads/my-video.mp4
```

You should see the job print again with `'status': 'COMPLETED'`.

### 3. Upload videos from the browser (optional)

The `web` service (a tiny static server on port 5006 that serves `StreamVideo/Web`) is part of the same compose and **starts automatically along with the pipeline** — no extra command needed. Just open **http://localhost:5006** in a browser and **drag & drop one or more videos**. They upload straight into `s3://streamvideo-input/raw/…` on LocalStack — no build step (Vue 3 and the AWS SDK are loaded from a CDN). The pipeline **watches `raw/` and processes each new video automatically**; the page shows the extracted data per video (status, real duration, resolutions, labels), reading it from the `streamvideo-jobs` table.

To stop everything (LocalStack included) and remove its data:

```bash
podman compose down -v
```

### Run the .NET port instead

Same flow, same LocalStack, C# implementation:

```bash
cd StreamVideo/DotNet/Pipeline
podman compose up --build pipeline
```

> On Windows, the `docker-compose.exe` that `podman compose` shells out to can hang while *building* (a Podman/Windows quirk). If that happens, build the image and start the stack in two steps:
>
> ```bash
> cd StreamVideo/DotNet/Pipeline
> podman build -t streamvideo-dotnet .
> podman compose up pipeline
> ```

---

## 🌩️ Deploying to AWS (CDK)

```bash
cd StreamVideo/Cdk
python -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt
cdk bootstrap
cdk deploy --context account=123456789012 --context region=us-east-1
```

The stack creates: S3 buckets, DynamoDB, SQS, SNS, 4 Lambdas, AWS Batch compute environment + job queue + ffmpeg job definition, the Step Functions state machine, an IAM role for EventBridge → Step Functions, and an EventBridge rule that triggers on `raw/*` object creation — plus two AWS Secrets Manager secrets (see below).

## 🔐 Secrets Manager

Passwords / secrets are never hardcoded. The CDK stack creates two secrets and the Lambdas fetch them at runtime via `boto3` `secretsmanager.get_secret_value`:

| Secret name | JSON layout | Read by | Used for |
|---|---|---|---|
| `StreamVideo/Analyzer` | `{ "analyzer_api_key": "..." }` | `analyze` Lambda | API key for the analysis provider (Rekognition + external analyzer) |
| `StreamVideo/Notifications` | `{ "hmac_signing_key": "..." }` | `notify` Lambda | HMAC-SHA256 signing key to sign every SNS message (`x-signature` attribute) |

Both secrets are created with `generate_secret_string` (random values, punctuation excluded), owned by IAM roles scoped via `secret.grant_read(lambda_role)` (least privilege: only the `analyze` and `notify` roles can read their own secret). Retrieve or inspect them with:

```bash
aws secretsmanager get-secret-value --secret-id StreamVideo/Analyzer --query SecretString --output text
aws secretsmanager get-secret-value --secret-id StreamVideo/Notifications --query SecretString --output text
```

To set a known value (rotation / explicit key), use `aws secretsmanager put-secret-value`:

```bash
aws secretsmanager put-secret-value \
  --secret-id StreamVideo/Notifications \
  --secret-string '{"hmac_signing_key":"your-own-key"}'
```

### ▶️ Try it live on real AWS

After `cdk deploy`, upload a video — EventBridge detects the new `raw/*` object and starts the Step Functions pipeline:

```bash
aws s3 cp demo.mp4 s3://streamvideo-input/raw/demo.mp4
```

Watch the job complete (created on the `PROCESSING` step, updated to `COMPLETED` on finalize):

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

```bash
# host toolchain
cd StreamVideo/Python/Pipeline && python -m pytest
cd StreamVideo/DotNet/Pipeline/src && dotnet test tests/StreamVideo.Tests.csproj -c Release

# or Podman-only, from the repo root
scripts/run-tests.sh  -Tech python -Project StreamVideo
scripts/run-tests.ps1 -Tech csharp -Project StreamVideo
```

Python uses **moto** (no LocalStack needed); the .NET suite uses in-memory doubles (no AWS needed).

| Language | Test | Coverage |
|---|---|---|
| Python / .NET | `test_demo_job_reaches_completed` / `Demo_Job_Reaches_Completed` | Full pipeline: object uploaded → status `COMPLETED`, labels + 3 resolutions, metadata. |
| Python / .NET | `test_failed_job_is_recorded` / `Failed_Job_Is_Recorded` | Transcoder failure → job status `FAILED`. |
| Python / .NET | `test_missing_video_raises` / `Missing_Video_Raises` | Non-existent object → file not found. |
| Python / .NET | `test_completion_event_is_buffered` / `Completion_Event_Is_Buffered_And_Delivered` | Completion event lands in SQS and is drained into SNS. |
| Python / .NET | `test_event_has_completion_payload` / `Event_Has_Completion_Payload` | Event carries `status`/`video_key`. |
| Python / .NET | `test_duration_comes_from_object_metadata` / `Duration_Comes_From_Object_Metadata` | Object metadata `duration` overrides the size-based fallback. |

## 📄 License

MIT — see [LICENSE](../LICENSE) in the repository root.
