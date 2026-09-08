# Build stage
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY src/StreamVideo.csproj .
RUN dotnet restore
COPY src/Config.cs src/Models.cs src/AwsClientFactory.cs src/Storage.cs src/Repository.cs src/Transcoding.cs src/Analysis.cs src/Notifications.cs src/VideoPipeline.cs src/Factory.cs src/Program.cs .
COPY src/Testing/ ./Testing/
RUN dotnet publish -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/runtime:10.0-alpine
WORKDIR /app
COPY --from=build /app/publish .
ENV INPUT_BUCKET=streamvideo-input
ENV OUTPUT_BUCKET=streamvideo-output
ENV JOBS_TABLE=streamvideo-jobs
ENV NOTIFY_QUEUE=streamvideo-notifications
ENV NOTIFY_TOPIC=streamvideo-notifications
ENV ANALYZER=local
ENV TRANSCODER=stub
ENTRYPOINT ["dotnet", "StreamVideo.dll"]