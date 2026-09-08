using System.Linq;

namespace StreamVideo.Testing;

/// <summary>In-memory storage double for local tests (mirrors S3 driver contract).</summary>
public sealed class InMemoryVideoStorage : IVideoStorage
{
    internal readonly Dictionary<string, byte[]> _objects = new();
    internal readonly Dictionary<string, IReadOnlyDictionary<string, string>> _metadata = new();
    public string InputBucket { get; set; } = "streamvideo-input";
    public string OutputBucket { get; set; } = "streamvideo-output";

    public Task EnsureStorageAsync(CancellationToken ct = default) => Task.CompletedTask;

    public void SetUserMetadata(string key, IReadOnlyDictionary<string, string> metadata) =>
        _metadata[key] = metadata;

    public Task<bool> ExistsAsync(string key, CancellationToken ct = default) =>
        Task.FromResult(_objects.ContainsKey(key));

    public Task PutAsync(string key, byte[] data, CancellationToken ct = default)
    {
        _objects[key] = data;
        return Task.CompletedTask;
    }

    public Task<byte[]> GetAsync(string key, CancellationToken ct = default) =>
        Task.FromResult(_objects[key]);

    public Task<IReadOnlyList<string>> ListAsync(string prefix, CancellationToken ct = default) =>
        Task.FromResult<IReadOnlyList<string>>(
            _objects.Keys.Where(k => k.StartsWith(prefix, StringComparison.Ordinal)).ToList()
        );

    public Task<long> SizeOfAsync(string key, CancellationToken ct = default) =>
        Task.FromResult((long)_objects[key].Length);

    public Task<IReadOnlyDictionary<string, string>> MetadataAsync(string key, CancellationToken ct = default) =>
        Task.FromResult(
            _metadata.TryGetValue(key, out IReadOnlyDictionary<string, string>? value)
                ? value
                : new Dictionary<string, string>()
        );

    public Task CopyAsync(string srcKey, string dstKey, CancellationToken ct = default)
    {
        _objects[dstKey] = _objects[srcKey];
        return Task.CompletedTask;
    }

    public string PublicUrl(string key) => $"s3://{OutputBucket}/{key}";
}