using Amazon.Rekognition;
using Amazon.Rekognition.Model;

namespace StreamVideo;

/// <summary>Content analysis adapters: Amazon Rekognition in the cloud, deterministic stub locally.</summary>
public interface IAnalyzer
{
    Task<List<string>> AnalyzeAsync(string videoKey, string name, CancellationToken ct = default);
}

/// <summary>Deterministic labels used by the emulated pipeline (no AI dependency).</summary>
public sealed class LocalAnalyzer : IAnalyzer
{
    public Task<List<string>> AnalyzeAsync(string videoKey, string name, CancellationToken ct = default) =>
        Task.FromResult(new List<string> { "person", "vehicle", "outdoor" });
}

/// <summary>Runs Amazon Rekognition Video label detection (start + poll).</summary>
public sealed class RekognitionAnalyzer : IAnalyzer
{
    private readonly AmazonRekognitionClient _client;
    private readonly int _pollSeconds;
    private readonly int _maxAttempts;

    public RekognitionAnalyzer(AmazonRekognitionClient client, int pollSeconds = 2, int maxAttempts = 120)
    {
        _client = client;
        _pollSeconds = pollSeconds;
        _maxAttempts = maxAttempts;
    }

    public async Task<List<string>> AnalyzeAsync(string videoKey, string name, CancellationToken ct = default)
    {
        var start = await _client.StartLabelDetectionAsync(
            new StartLabelDetectionRequest
            {
                Video = new Video
                {
                    S3Object = new S3Object { Bucket = Config.InputBucket(), Name = videoKey },
                },
            },
            ct
        );
        string jobId = start.JobId;

        for (int attempt = 0; attempt < _maxAttempts; attempt++)
        {
            var result = await _client.GetLabelDetectionAsync(
                new GetLabelDetectionRequest { JobId = jobId },
                ct
            );
            if (result.JobStatus == "SUCCEEDED")
            {
                return result.Labels
                    .Select(item => item.Label.Name)
                    .Distinct()
                    .OrderBy(label => label)
                    .ToList();
            }
            if (result.JobStatus == "FAILED")
            {
                throw new InvalidOperationException($"Rekognition job failed: {result.StatusMessage}");
            }
            await Task.Delay(TimeSpan.FromSeconds(_pollSeconds), ct);
        }

        throw new TimeoutException($"Timed out waiting for Rekognition job {jobId}");
    }
}