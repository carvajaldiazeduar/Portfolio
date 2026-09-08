namespace StreamVideo.Testing;

/// <summary>In-memory storage double for local tests (mirrors S3 driver contract).</summary>
public sealed class InMemoryVideoStorage : IVideoStorage
{
    private readonly Dictionary<string, byte[]> _objects = new();
    public string InputBucket { get; set; } = "streamvideo-input";
    public string OutputBucket { get; set; } = "streamvideo-output";

    public Task EnsureStorageAsync(CancellationToken ct = default) => Task.CompletedTask;

    public Task<bool> ExistsAsync(string key, CancellationToken ct = default) =>
        Task.FromResult(_objects.ContainsKey(key));

    public Task PutAsync(string key, byte[] data, CancellationToken ct = default)
    {
        _objects[key] = data;
        return Task.CompletedTask;
    }

    public Task<byte[]> GetAsync(string key, CancellationToken ct = default) =>
        Task.FromResult(_objects[key]);

    public Task<long> SizeOfAsync(string key, CancellationToken ct = default) =>
        Task.FromResult((long)_objects[key].Length);

    public Task CopyAsync(string srcKey, string dstKey, CancellationToken ct = default)
    {
        _objects[dstKey] = _objects[srcKey];
        return Task.CompletedTask;
    }

    public string PublicUrl(string key) => $"s3://{OutputBucket}/{key}";
}