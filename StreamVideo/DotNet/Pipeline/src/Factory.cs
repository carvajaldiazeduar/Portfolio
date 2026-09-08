namespace StreamVideo;

/// <summary>Wires every adapter from environment variables (driver pattern).</summary>
public static class Factory
{
    public static VideoPipeline Build()
    {
        S3VideoStorage storage = new(AwsClientFactory.S3(), Config.InputBucket(), Config.OutputBucket());
        DynamoDbJobRepository repository = new(AwsClientFactory.DynamoDb(), Config.JobsTable());

        string transcoderDriver = Config.TranscoderDriver();
        if (transcoderDriver != "stub")
        {
            throw new InvalidOperationException($"Unsupported TRANSCODER driver: {transcoderDriver}");
        }
        ITranscoder transcoder = new StubTranscoder(storage);

        IAnalyzer analyzer = Config.AnalyzerDriver() switch
        {
            "local" => new LocalAnalyzer(),
            "rekognition" => new RekognitionAnalyzer(AwsClientFactory.Rekognition()),
            string driver => throw new InvalidOperationException($"Unsupported ANALYZER driver: {driver}"),
        };

        SqsSnsNotifier notifier = new(
            AwsClientFactory.Sqs(),
            AwsClientFactory.Sns(),
            Config.NotifyQueue(),
            Config.NotifyTopic()
        );

        return new VideoPipeline(storage, repository, transcoder, analyzer, notifier);
    }
}