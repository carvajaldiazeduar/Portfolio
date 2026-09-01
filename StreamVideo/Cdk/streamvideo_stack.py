"""StreamVideo AWS infrastructure as CDK.

Event flow on AWS:
  S3 (ObjectCreated) -> EventBridge -> Step Functions
      metadata (Lambda) -> parallel[ transcode (Batch/Fargate ffmpeg),
                                    analyze (Lambda + Rekognition) ]
      -> finalize (Lambda + DynamoDB) -> SQS -> notify (Lambda) -> SNS
"""

from __future__ import annotations

import os
from pathlib import Path

from aws_cdk import (
    RemovalPolicy,
    Stack,
    Duration,
    aws_batch as batch,
    aws_dynamodb as dynamodb,
    aws_ec2 as ec2,
    aws_events as events,
    aws_events_targets as targets,
    aws_iam as iam,
    aws_lambda as lambda_,
    aws_lambda_event_sources as event_sources,
    aws_s3 as s3,
    aws_sns as sns,
    aws_sqs as sqs,
    aws_stepfunctions as sfn,
    aws_stepfunctions_tasks as tasks,
)
from aws_cdk import CfnOutput

LAMBDAS_DIR = str(Path(__file__).parent / "lambdas")

JOBS_TABLE = "streamvideo-jobs"


def lambda_role(scope: Stack, name: str, **statements) -> iam.Role:
    role = iam.Role(
        scope,
        f"{name}Role",
        assumed_by=iam.ServicePrincipal("lambda.amazonaws.com"),
    )
    role.add_to_policy(
        iam.PolicyStatement(actions=["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], resources=["*"])
    )
    for statement in statements.values():
        role.add_to_policy(statement)
    return role


class StreamVideoStack(Stack):
    def __init__(self, scope, id, **kwargs):
        super().__init__(scope, id, **kwargs)

        partition = self.partition
        region = self.region
        account = self.account

        input_bucket = s3.Bucket(
            self,
            "Input",
            bucket_name="streamvideo-input-ta",
            removal_policy=RemovalPolicy.DESTROY,
            auto_delete_objects=True,
        )
        output_bucket = s3.Bucket(
            self,
            "Output",
            bucket_name="streamvideo-output-ta",
            removal_policy=RemovalPolicy.DESTROY,
            auto_delete_objects=True,
        )

        jobs_table = dynamodb.Table(
            self,
            "Jobs",
            table_name=JOBS_TABLE,
            partition_key=dynamodb.Attribute(
                name="video_key", type=dynamodb.AttributeType.STRING
            ),
            billing_mode=dynamodb.BillingMode.PAY_PER_REQUEST,
            removal_policy=RemovalPolicy.DESTROY,
        )

        notifications_queue = sqs.Queue(
            self,
            "Notifications",
            queue_name="streamvideo-notifications",
            visibility_timeout=Duration.seconds(60),
            removal_policy=RemovalPolicy.DESTROY,
        )

        topic = sns.Topic(
            self,
            "VideoNotifications",
            topic_name="streamvideo-notifications",
        )

        metadata_role = lambda_role(
            self,
            "Metadata",
            s3_read=iam.PolicyStatement(
                actions=["s3:GetObject", "s3:HeadObject"],
                resources=[f"arn:{partition}:s3:::{input_bucket.bucket_name}/*"],
            ),
            dynamodb_write=iam.PolicyStatement(
                actions=["dynamodb:PutItem"],
                resources=[jobs_table.table_arn],
            ),
        )
        metadata_fn = lambda_.Function(
            self,
            "Metadata",
            runtime=lambda_.Runtime.PYTHON_3_12,
            code=lambda_.Code.from_asset(LAMBDAS_DIR),
            handler="metadata.handler",
            role=metadata_role,
            timeout=Duration.seconds(30),
            environment={"JOBS_TABLE": jobs_table.table_name, "INPUT_BUCKET": input_bucket.bucket_name},
        )

        analyze_role = lambda_role(
            self,
            "Analyze",
            s3_read=iam.PolicyStatement(
                actions=["s3:GetObject", "s3:HeadObject"],
                resources=[f"arn:{partition}:s3:::{input_bucket.bucket_name}/*"],
            ),
            rekognition=iam.PolicyStatement(
                actions=["rekognition:StartLabelDetection", "rekognition:GetLabelDetection"],
                resources=["*"],
            ),
        )
        analyze_fn = lambda_.Function(
            self,
            "Analyze",
            runtime=lambda_.Runtime.PYTHON_3_12,
            code=lambda_.Code.from_asset(LAMBDAS_DIR),
            handler="analyze.handler",
            role=analyze_role,
            timeout=Duration.minutes(5),
        )

        finalize_role = lambda_role(
            self,
            "Finalize",
            dynamodb_write=iam.PolicyStatement(
                actions=["dynamodb:UpdateItem"],
                resources=[jobs_table.table_arn],
            ),
        )
        finalize_fn = lambda_.Function(
            self,
            "Finalize",
            runtime=lambda_.Runtime.PYTHON_3_12,
            code=lambda_.Code.from_asset(LAMBDAS_DIR),
            handler="finalize.handler",
            role=finalize_role,
            timeout=Duration.seconds(30),
            environment={
                "JOBS_TABLE": jobs_table.table_name,
                "OUTPUT_BUCKET": output_bucket.bucket_name,
            },
        )

        notify_role = lambda_role(
            self,
            "Notify",
            sqs_poll=iam.PolicyStatement(
                actions=["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"],
                resources=[notifications_queue.queue_arn],
            ),
            sns_publish=iam.PolicyStatement(
                actions=["sns:Publish"], resources=[topic.topic_arn]
            ),
        )
        notify_fn = lambda_.Function(
            self,
            "Notify",
            runtime=lambda_.Runtime.PYTHON_3_12,
            code=lambda_.Code.from_asset(LAMBDAS_DIR),
            handler="notify.handler",
            role=notify_role,
            timeout=Duration.seconds(15),
            environment={"NOTIFY_TOPIC_ARN": topic.topic_arn},
        )
        notify_fn.add_event_source(
            event_sources.SqsEventSource(notifications_queue, batch_size=10)
        )

        vpc = ec2.Vpc(self, "Vpc", max_azs=2)

        compute_env = batch.CfnComputeEnvironment(
            self,
            "ComputeEnv",
            type="MANAGED",
            state="ENABLED",
            compute_resources={
                "type": "FARGATE",
                "subnets": vpc.select_subnets(
                    subnet_type=ec2.SubnetType.PRIVATE_WITH_EGRESS
                ).subnet_ids,
                "maxvCpus": 32,
            },
        )
        job_queue = batch.CfnJobQueue(
            self,
            "JobQueue",
            priority=1,
            state="ENABLED",
            compute_environment_order=[
                {"computeEnvironment": compute_env.ref, "order": 1}
            ],
        )

        batch_exec_role = iam.Role(
            self,
            "BatchExecRole",
            assumed_by=iam.ServicePrincipal("ecs-tasks.amazonaws.com"),
        )
        batch_exec_role.add_to_policy(
            iam.PolicyStatement(
                actions=["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
                resources=["*"],
            )
        )
        batch_task_role = iam.Role(
            self,
            "BatchTaskRole",
            assumed_by=iam.ServicePrincipal("ecs-tasks.amazonaws.com"),
        )
        batch_task_role.add_to_policy(
            iam.PolicyStatement(
                actions=["s3:GetObject", "s3:HeadObject"],
                resources=[f"arn:{partition}:s3:::{input_bucket.bucket_name}/*"],
            )
        )
        batch_task_role.add_to_policy(
            iam.PolicyStatement(
                actions=["s3:PutObject"],
                resources=[f"arn:{partition}:s3:::{output_bucket.bucket_name}/*"],
            )
        )

        job_def = batch.CfnJobDefinition(
            self,
            "TranscodeJobDef",
            type="container",
            container_properties={
                "image": "jrottenberg/ffmpeg:6.0-alpine",
                "jobRoleArn": batch_task_role.role_arn,
                "executionRoleArn": batch_exec_role.role_arn,
                "platformCapabilities": ["FARGATE"],
                "resourceRequirements": [
                    {"type": "VCPU", "value": "1"},
                    {"type": "MEMORY", "value": "2048"},
                ],
                "command": [
                    "Ref::src",
                    "Ref::dst",
                ],
            },
        )

        state_machine_role = iam.Role(
            self,
            "StateMachineRole",
            assumed_by=iam.ServicePrincipal("states.amazonaws.com"),
        )
        for fn in (metadata_fn, analyze_fn, finalize_fn):
            fn.grant_invoke(state_machine_role)
        state_machine_role.add_to_policy(
            iam.PolicyStatement(
                actions=["sqs:SendMessage"],
                resources=[notifications_queue.queue_arn],
            )
        )
        state_machine_role.add_to_policy(
            iam.PolicyStatement(
                actions=["batch:SubmitJob", "batch:DescribeJobs"],
                resources=[
                    f"arn:{partition}:batch:{region}:{account}:job-definition/*",
                    f"arn:{partition}:batch:{region}:{account}:job-queue/*",
                    f"arn:{partition}:batch:{region}:{account}:job/*",
                ],
            )
        )

        metadata_step = tasks.LambdaInvoke(
            self,
            "MetadataStep",
            lambda_function=metadata_fn,
            result_path="$.metadata",
        )

        normalize = sfn.Pass(
            self,
            "Normalize",
            parameters={
                "bucket.$": "$.metadata.Payload.bucket",
                "video_key.$": "$.metadata.Payload.video_key",
                "metadata.$": "$.metadata.Payload.metadata",
            },
            result_path="$.job",
        )

        analyze_step = tasks.LambdaInvoke(
            self,
            "AnalyzeStep",
            lambda_function=analyze_fn,
            result_path="$.analysis",
            result_selector={"labels.$": "$.Payload"},
        )

        transcode_step = tasks.BatchSubmitJob(
            self,
            "TranscodeStep",
            job_definition_arn=job_def.ref,
            job_queue_arn=job_queue.attr_job_queue_arn,
            job_name="transcode",
            integration_pattern=sfn.IntegrationPattern.RUN_JOB,
            input_path="$.job",
            result_path="$.transcode",
            payload=sfn.TaskInput.from_object(
                {
                    "Parameters": {
                        "src": sfn.JsonPath.format(
                            "s3://{}/{}",
                            input_bucket.bucket_name,
                            sfn.JsonPath.string_at("$.video_key"),
                        ),
                        "dst": sfn.JsonPath.format(
                            "s3://{}/transcoded/{}",
                            output_bucket.bucket_name,
                            sfn.JsonPath.string_at("$.video_key"),
                        ),
                    }
                }
            ),
        )

        finalize_step = tasks.LambdaInvoke(
            self,
            "FinalizeStep",
            lambda_function=finalize_fn,
            payload=sfn.TaskInput.from_object(
                {
                    "bucket.$": "$.job.bucket",
                    "video_key.$": "$.job.video_key",
                    "labels.$": "$.analysis.labels",
                    "metadata.$": "$.job.metadata",
                }
            ),
            result_path="$.result",
        )

        publish_step = tasks.SqsSendMessage(
            self,
            "PublishStep",
            queue=notifications_queue,
            message_body=sfn.TaskInput.from_object(
                {"Payload.$": "$.result.Payload"}
            ),
            result_path="$.published",
        )

        parallel = sfn.Parallel(self, "Process", result_path="$.branches")
        parallel.branch(analyze_step)
        parallel.branch(transcode_step)

        definition = (
            metadata_step
            .next(normalize)
            .next(parallel)
            .next(finalize_step)
            .next(publish_step)
        )

        state_machine = sfn.StateMachine(
            self,
            "VideoPipeline",
            state_machine_name="streamvideo-pipeline",
            definition_body=sfn.DefinitionBody.from_chainable(definition),
            role=state_machine_role,
            timeout=Duration.hours(1),
        )

        ingest_rule = events.Rule(
            self,
            "IngestRule",
            event_pattern=events.EventPattern(
                source=["aws.s3"],
                detail_type=["Object Created"],
                detail={
                    "bucket": {"name": [input_bucket.bucket_name]},
                    "object": {"key": [{"prefix": "raw/"}]},
                },
            ),
        )
        ingest_rule.add_target(
            targets.SfnStateMachine(
                state_machine,
                input=events.RuleTargetInput.from_event_path("$"),
            )
        )

        CfnOutput(self, "InputBucket", value=input_bucket.bucket_name)
        CfnOutput(self, "OutputBucket", value=output_bucket.bucket_name)
        CfnOutput(self, "JobsTable", value=jobs_table.table_name)
        CfnOutput(self, "NotificationQueue", value=notifications_queue.queue_name)
        CfnOutput(self, "NotificationTopic", value=topic.topic_arn)
        CfnOutput(self, "StateMachine", value=state_machine.state_machine_arn)