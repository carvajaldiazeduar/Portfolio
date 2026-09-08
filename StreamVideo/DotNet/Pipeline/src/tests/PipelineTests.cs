using System.Text.Json;
using StreamVideo;
using StreamVideo.Testing;
using Xunit;

namespace StreamVideo.Tests;

public class PipelineTests
{
    private static byte[] SampleVideo()
    {
        MemoryStream buffer = new();
        for (int index = 0; index < 32; index++)
        {
            byte[] frame = System.Text.Encoding.ASCII.GetBytes($"frame-{index:D4}-");
            for (int repeat = 0; repeat < 64; repeat++)
            {
                buffer.Write(frame);
            }
        }
        return buffer.ToArray();
    }

    private static async Task<VideoPipeline> BuildPipelineAsync()
    {
        InMemoryVideoStorage storage = new();
        InMemoryJobRepository repository = new();
        InMemoryNotifier notifier = new();
        VideoPipeline pipeline = new VideoPipeline(
            storage,
            repository,
            new StubTranscoder(storage),
            new LocalAnalyzer(),
            notifier
        );
        await pipeline.InitResourcesAsync();
        return pipeline;
    }

    [Fact]
    public async Task Demo_Job_Reaches_Completed()
    {
        const string key = "raw/launch-demo.mp4";
        VideoPipeline pipeline = await BuildPipelineAsync();
        await pipeline.Storage.PutAsync(key, SampleVideo());

        Dictionary<string, object?>? job = await pipeline.ProcessAsync(key);

        Assert.NotNull(job);
        Assert.Equal(JobStatus.Completed, job!["status"]);
        Assert.Equal(new[] { "person", "vehicle", "outdoor" }, job["labels"]);

        Dictionary<string, string> outputs = Assert.IsType<Dictionary<string, string>>(job["outputs"]);
        Assert.Equal(StubTranscoder.Resolutions, outputs.Keys);

        Dictionary<string, object?> metadata = Assert.IsType<Dictionary<string, object?>>(job["metadata"]);
        Assert.Equal(key, metadata["key"]);
    }

    [Fact]
    public async Task Failed_Job_Is_Recorded()
    {
        const string key = "raw/broken.mp4";
        InMemoryVideoStorage storage = new();
        InMemoryJobRepository repository = new();
        VideoPipeline pipeline = new VideoPipeline(
            storage,
            repository,
            new FailingTranscoder(),
            new LocalAnalyzer(),
            new InMemoryNotifier()
        );
        await storage.PutAsync(key, SampleVideo());

        await Assert.ThrowsAsync<InvalidOperationException>(() => pipeline.ProcessAsync(key));

        Dictionary<string, object?>? job = await repository.GetJobAsync(key);
        Assert.NotNull(job);
        Assert.Equal(JobStatus.Failed, job!["status"]);
    }

    [Fact]
    public async Task Missing_Video_Raises()
    {
        VideoPipeline pipeline = await BuildPipelineAsync();

        await Assert.ThrowsAsync<FileNotFoundException>(() => pipeline.ProcessAsync("does/not/exist.mp4"));
    }

    [Fact]
    public async Task Duration_Comes_From_Object_Metadata()
    {
        const string key = "raw/known.mp4";
        InMemoryVideoStorage storage = new();
        InMemoryJobRepository repository = new();
        InMemoryNotifier notifier = new();
        VideoPipeline pipeline = new VideoPipeline(
            storage,
            repository,
            new StubTranscoder(storage),
            new LocalAnalyzer(),
            notifier
        );
        await pipeline.InitResourcesAsync();
        await storage.PutAsync(key, SampleVideo());
        storage.SetUserMetadata(key, new Dictionary<string, string> { ["duration"] = "12.5" });

        Dictionary<string, object?>? job = await pipeline.ProcessAsync(key);

        Dictionary<string, object?> metadata = Assert.IsType<Dictionary<string, object?>>(job!["metadata"]);
        Assert.Equal(12.5, metadata["duration_sec"]);
    }

    [Fact]
    public async Task Completion_Event_Is_Buffered_And_Delivered()
    {
        const string key = "raw/event.mp4";
        VideoPipeline pipeline = await BuildPipelineAsync();
        await pipeline.Storage.PutAsync(key, SampleVideo());
        await pipeline.ProcessAsync(key);

        InMemoryNotifier notifier = Assert.IsType<InMemoryNotifier>(pipeline.Notifier);
        int handled = await notifier.ConsumeOnceAsync(_ => Task.CompletedTask);

        Assert.Equal(1, handled);
        Assert.Equal(1, notifier.Delivered);
    }

    [Fact]
    public async Task Event_Has_Completion_Payload()
    {
        const string key = "raw/event.mp4";
        VideoPipeline pipeline = await BuildPipelineAsync();
        await pipeline.Storage.PutAsync(key, SampleVideo());
        await pipeline.ProcessAsync(key);

        InMemoryNotifier notifier = Assert.IsType<InMemoryNotifier>(pipeline.Notifier);
        Assert.Single(notifier.Messages);

        Dictionary<string, object?>? eventData = JsonSerializer.Deserialize<Dictionary<string, object?>>(notifier.Messages[0]);
        Assert.NotNull(eventData);
        Assert.Equal(JobStatus.Completed, eventData!["status"]?.ToString());
        Assert.Equal(key, eventData["video_key"]?.ToString());
    }

    private sealed class FailingTranscoder : ITranscoder
    {
        public Task<Dictionary<string, string>> TranscodeAsync(
            string videoKey,
            string name,
            byte[] data,
            CancellationToken ct = default
        ) => throw new InvalidOperationException("transcode failed");
    }
}