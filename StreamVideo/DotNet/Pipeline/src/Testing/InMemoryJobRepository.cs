namespace StreamVideo.Testing;

/// <summary>In-memory job repository double for local tests (mirrors DynamoDB driver contract).</summary>
public sealed class InMemoryJobRepository : IJobRepository
{
    private readonly Dictionary<string, Dictionary<string, object?>> _jobs = new();

    public Task EnsureTableAsync(CancellationToken ct = default) => Task.CompletedTask;

    public Task CreateJobAsync(string videoKey, CancellationToken ct = default)
    {
        _jobs[videoKey] = new Dictionary<string, object?>
        {
            ["video_key"] = videoKey,
            ["status"] = JobStatus.Processing,
            ["created_at"] = DateTimeOffset.UtcNow.ToUnixTimeSeconds(),
        };
        return Task.CompletedTask;
    }

    public Task UpdateJobAsync(
        string videoKey,
        IReadOnlyDictionary<string, object?> fields,
        CancellationToken ct = default
    )
    {
        if (!_jobs.TryGetValue(videoKey, out Dictionary<string, object?> job))
        {
            job = _jobs[videoKey] = new Dictionary<string, object?>();
        }
        foreach ((string key, object? value) in fields)
        {
            job[key] = value;
        }
        job["updated_at"] = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        return Task.CompletedTask;
    }

    public Task<Dictionary<string, object?>?> GetJobAsync(string videoKey, CancellationToken ct = default) =>
        Task.FromResult(
            _jobs.TryGetValue(videoKey, out Dictionary<string, object?> job) ? new Dictionary<string, object?>(job) : null
        );
}