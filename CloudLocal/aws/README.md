# AWS Local Services

AWS local development is centered on LocalStack.

## Services

- S3
- DynamoDB
- SQS
- SNS
- Lambda
- CloudWatch

## Run

From `CloudLocal`:

```bash
podman compose --profile aws up
```

For the full pipeline demo:

```bash
cd CloudLocal/aws/localstack/pipeline/Node.js/Web/Plain
podman compose up
```

## Endpoint

```env
AWS_ENDPOINT_URL=http://localhost:4566
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=mock_key
AWS_SECRET_ACCESS_KEY=mock_secret
```
