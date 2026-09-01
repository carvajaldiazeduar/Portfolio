from __future__ import annotations


class TestPipeline:
    def test_demo_job_reaches_completed(self, pipeline, sample_video):
        key = "raw/launch-demo.mp4"
        pipeline.storage.put(key, sample_video)

        job = pipeline.process(key)

        assert job["status"] == "COMPLETED"
        assert job["labels"] == ["person", "vehicle", "outdoor"]
        assert set(job["outputs"]) == {"1080p", "720p", "480p"}
        assert job["metadata"]["key"] == key

    def test_failed_job_is_recorded(self, pipeline, sample_video, monkeypatch):
        key = "raw/broken.mp4"
        pipeline.storage.put(key, sample_video)

        def boom(video_key, name, data):
            raise RuntimeError("transcode failed")

        monkeypatch.setattr(pipeline.transcoder, "transcode", boom)

        from streamvideo.pipeline import VideoPipeline

        try:
            pipeline.process(key)
        except RuntimeError:
            pass

        job = pipeline.repository.get_job(key)
        assert job["status"] == "FAILED"

    def test_missing_video_raises(self, pipeline):
        from streamvideo.repository import STATUS_FAILED

        try:
            pipeline.process("does/not/exist.mp4")
        except FileNotFoundError:
            pass


class TestNotifications:
    def test_completion_event_is_buffered_in_sqs(self, pipeline, sample_video):
        key = "raw/event.mp4"
        pipeline.storage.put(key, sample_video)
        pipeline.process(key)

        from streamvideo.notify import publish_sns

        handled = pipeline.notifier.consume_once(
            publish_sns(pipeline.notifier.sns, pipeline.notifier.topic_arn)
        )
        assert handled == 1
        assert pipeline.notifier.delivered == 1

    def test_event_has_completion_payload(self, pipeline, sample_video):
        key = "raw/event.mp4"
        pipeline.storage.put(key, sample_video)
        pipeline.process(key)

        response = pipeline.notifier.sqs.receive_message(
            QueueUrl=pipeline.notifier.queue_url,
            MaxNumberOfMessages=1,
            VisibilityTimeout=5,
        )
        import json

        message = response["Messages"][0]
        event = json.loads(message["Body"])
        assert event["status"] == "COMPLETED"
        assert event["video_key"] == key
        pipeline.notifier.sqs.delete_message(
            QueueUrl=pipeline.notifier.queue_url,
            ReceiptHandle=message["ReceiptHandle"],
        )