namespace StreamVideo;

/// <summary>VideoPipeline: the orchestration flow shared by the local runner and AWS.</summary>
public sealed class VideoPipeline
{
    private readonly IVideoStorage _storage;
    private readonly IJobRepository _repository;
    private readonly ITranscoder _transcoder;
    private readonly IAnalyzer _analyzer;
    private readonly INotifier _notifier;

    public IVideoStorage Storage => _storage;
    public IJobRepository Repository => _repository;
    public ITranscoder Transcoder => _transcoder;
    public INotifier Notifier => _notifier;

    public VideoPipeline(
        IVideoStorage storage,
        IJobRepository repository,
        ITranscoder transcoder,
        IAnalyzer analyzer,
        INotifier notifier
    )
    {
        _storage = storage;
        _repository = repository;
        _transcoder = transcoder;
        _analyzer = analyzer;
        _notifier = notifier;
    }

    /// <summary>Lightweight metadata approximation used locally; the real metadata
    /// extractor is the `metadata` Lambda in the CDK stack.</summary>
    public static Dictionary<string, object?> EstimateMetadata(string videoKey, long size)
    {
        string extension = Path.GetExtension(videoKey).TrimStart('.').ToLowerInvariant();
        long seconds = Math.Max(1, size / (2 * 1024 * 1024));
        return new Dictionary<string, object?>
        {
            ["key"] = videoKey,
            ["container"] = extension.Length == 0 ? "mp4" : extension,
            ["duration_sec"] = seconds,
            ["size_bytes"] = size,
        };
    }

    public async Task InitResourcesAsync(CancellationToken ct = default)
    {
        await _storage.EnsureStorageAsync(ct);
        await _repository.EnsureTableAsync(ct);
        await _notifier.EnsureResourcesAsync(ct);
    }

    public async Task<Dictionary<string, object?>?> ProcessAsync(string videoKey, CancellationToken ct = default)
    {
        if (!await _storage.ExistsAsync(videoKey, ct))
        {
            throw new FileNotFoundException($"No video object '{videoKey}' in storage", videoKey);
        }

        await _repository.CreateJobAsync(videoKey, ct);
        try
        {
            long size = await _storage.SizeOfAsync(videoKey, ct);
            byte[] data = await _storage.GetAsync(videoKey, ct);
            string name = videoKey.Substring(videoKey.LastIndexOf('/') + 1);

            Dictionary<string, string> outputs = await _transcoder.TranscodeAsync(videoKey, name, data, ct);
            List<string> labels = await _analyzer.AnalyzeAsync(videoKey, name, ct);

            Dictionary<string, string> urls = outputs.ToDictionary(pair => pair.Key, pair => _storage.PublicUrl(pair.Value));
            Dictionary<string, object?> metadata = EstimateMetadata(videoKey, size);

            IReadOnlyDictionary<string, string> userMetadata = await _storage.MetadataAsync(videoKey, ct);
            foreach (KeyValuePair<string, string> entry in userMetadata)
            {
                if (
                    entry.Key.EndsWith("duration", StringComparison.OrdinalIgnoreCase) &&
                    double.TryParse(entry.Value, System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out double duration) &&
                    duration > 0
                )
                {
                    metadata["duration_sec"] = duration;
                    break;
                }
            }

            await _repository.UpdateJobAsync(
                videoKey,
                new Dictionary<string, object?>
                {
                    ["status"] = JobStatus.Completed,
                    ["metadata"] = metadata,
                    ["outputs"] = urls,
                    ["labels"] = labels,
                },
                ct
            );

            Dictionary<string, object?> eventData = new()
            {
                ["video_key"] = videoKey,
                ["status"] = JobStatus.Completed,
                ["labels"] = labels,
                ["outputs"] = urls,
            };
            await _notifier.SendAsync(eventData, ct);

            return await _repository.GetJobAsync(videoKey, ct);
        }
        catch
        {
            await _repository.UpdateJobAsync(
                videoKey,
                new Dictionary<string, object?> { ["status"] = JobStatus.Failed },
                ct
            );
            throw;
        }
    }
}