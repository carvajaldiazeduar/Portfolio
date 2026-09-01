FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src /app/src

ENV PYTHONPATH=/app/src
ENV INPUT_BUCKET=streamvideo-input
ENV OUTPUT_BUCKET=streamvideo-output
ENV JOBS_TABLE=streamvideo-jobs
ENV NOTIFY_QUEUE=streamvideo-notifications
ENV NOTIFY_TOPIC=streamvideo-notifications
ENV ANALYZER=local
ENV TRANSCODER=stub

ENTRYPOINT ["python", "-m", "streamvideo.runner"]