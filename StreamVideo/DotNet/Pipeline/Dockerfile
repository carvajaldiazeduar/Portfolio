# Build stage
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY src/StreamVideo.csproj .
RUN dotnet restore
COPY src/ .
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