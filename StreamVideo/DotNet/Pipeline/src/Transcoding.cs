namespace StreamVideo;

/// <summary>Transcoding adapters: real AWS runs ffmpeg in Batch, local stubs copy the stream.</summary>
public interface ITranscoder
{
    Task<Dictionary<string, string>> TranscodeAsync(
        string videoKey,
        string name,
        byte[] data,
        CancellationToken ct = default
    );
}

/// <summary>Emulates the heavy transcode step locally by re-uploading the stream
/// once per target resolution. The real ffmpeg job lives in AWS Batch
/// (see the CDK stack).</summary>
public sealed class StubTranscoder : ITranscoder
{
    public static readonly string[] Resolutions = { "1080p", "720p", "480p" };

    private readonly IVideoStorage _storage;

    public StubTranscoder(IVideoStorage storage) => _storage = storage;

    public async Task<Dictionary<string, string>> TranscodeAsync(
        string videoKey,
        string name,
        byte[] data,
        CancellationToken ct = default
    )
    {
        var outputs = new Dictionary<string, string>();
        foreach (string resolution in Resolutions)
        {
            string destination = $"transcoded/{resolution}/{name}";
            await _storage.CopyAsync(videoKey, destination, ct);
            outputs[resolution] = destination;
        }
        return outputs;
    }
}