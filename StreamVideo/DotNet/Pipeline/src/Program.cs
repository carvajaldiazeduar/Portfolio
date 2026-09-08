using StreamVideo;

return await Runner.RunAsync(args);

/// <summary>Command line entry points for the emulated pipeline.
/// Commands: init, demo, worker, ingest.</summary>
public static class Runner
{
    public const string SampleVideoKey = "raw/launch-demo.mp4";

    public static async Task<int> RunAsync(string[] args)
    {
        if (args.Length == 0)
        {
            PrintUsage();
            return 2;
        }

        return args[0] switch
        {
            "init" => await CmdInitAsync(),
            "demo" => await CmdDemoAsync(),
            "worker" => await CmdWorkerAsync(),
            "ingest" when args.Length < 2 => PrintUsage("ingest requires <file>", 2),
            "ingest" => await CmdIngestAsync(args[1]),
            _ => PrintUsage($"Unknown command: {args[0]}", 2),
        };
    }

    private static Task<int> CmdInitAsync()
    {
        var pipeline = Factory.Build();
        return InitAndReportAsync(pipeline);
    }

    private static async Task<int> CmdDemoAsync()
    {
        var pipeline = Factory.Build();
        await pipeline.InitResourcesAsync();
        byte[] video = SampleVideo();
        await pipeline.Storage.PutAsync(SampleVideoKey, video);
        Console.WriteLine($"Uploaded sample video -> s3://{Config.InputBucket()}/{SampleVideoKey} ({video.Length} bytes)");

        var job = await pipeline.ProcessAsync(SampleVideoKey);
        Console.WriteLine("Job finished:");
        Console.WriteLine(ToJson(job));

        var notifier = AsSqsSnsNotifier(pipeline);
        var deliver = SnsPublisher.For(notifier.Sns, notifier.TopicArn);
        for (int attempt = 0; attempt < 5; attempt++)
        {
            int handled = await notifier.ConsumeOnceAsync(deliver);
            if (handled == 0 && notifier.Delivered > 0)
            {
                break;
            }
            await Task.Delay(500);
        }
        Console.WriteLine("Notifications delivered via SNS: " + notifier.Delivered);
        return 0;
    }

    private static async Task<int> CmdWorkerAsync()
    {
        var pipeline = Factory.Build();
        await pipeline.InitResourcesAsync();
        var notifier = AsSqsSnsNotifier(pipeline);
        var deliver = SnsPublisher.For(notifier.Sns, notifier.TopicArn);
        Console.WriteLine($"Worker consuming {notifier.QueueName} -> topic {notifier.TopicName} (Ctrl+C to stop)");

        using var cts = new CancellationTokenSource();
        Console.CancelKeyPress += (_, e) =>
        {
            e.Cancel = true;
            cts.Cancel();
        };

        try
        {
            while (!cts.IsCancellationRequested)
            {
                await notifier.ConsumeOnceAsync(deliver, cts.Token);
                await Task.Delay(1000, cts.Token);
            }
        }
        catch (OperationCanceledException)
        {
            // Ctrl+C
        }
        return 0;
    }

    private static async Task<int> CmdIngestAsync(string filePath)
    {
        var pipeline = Factory.Build();
        await pipeline.InitResourcesAsync();
        string key = "ingested/" + Path.GetFileName(filePath);
        byte[] data = await File.ReadAllBytesAsync(filePath);
        await pipeline.Storage.PutAsync(key, data);
        Console.WriteLine($"Uploaded -> s3://{Config.InputBucket()}/{key}");
        Console.WriteLine(ToJson(await pipeline.ProcessAsync(key)));
        return 0;
    }

    private static async Task<int> InitAndReportAsync(VideoPipeline pipeline)
    {
        await pipeline.InitResourcesAsync();
        Console.WriteLine("Resources ready: " + Config.InputBucket());
        return 0;
    }

    private static SqsSnsNotifier AsSqsSnsNotifier(VideoPipeline pipeline) =>
        pipeline.Notifier as SqsSnsNotifier
        ?? throw new InvalidOperationException("Pipeline notifier is not the SQS/SNS driver");

    private static byte[] SampleVideo()
    {
        using var buffer = new MemoryStream();
        for (int index = 0; index < 256; index++)
        {
            byte[] frame = System.Text.Encoding.ASCII.GetBytes($"frame-{index:D4}-");
            for (int repeat = 0; repeat < 128; repeat++)
            {
                buffer.Write(frame);
            }
        }
        return buffer.ToArray();
    }

    private static string ToJson(Dictionary<string, object?>? value) =>
        System.Text.Json.JsonSerializer.Serialize(
            value,
            new System.Text.Json.JsonSerializerOptions { WriteIndented = true }
        );

    private static int PrintUsage(string message = "", int exitCode = 0)
    {
        if (message.Length > 0)
        {
            Console.Error.WriteLine(message);
        }
        Console.WriteLine("Usage: dotnet StreamVideo.dll <init|demo|worker|ingest [file]>");
        return exitCode;
    }
}