namespace StreamVideo;

/// <summary>Environment-driven configuration shared by every adapter.</summary>
public static class Config
{
    public static string Env(string name) => Environment.GetEnvironmentVariable(name) ?? "";

    public static string EnvOr(string name, string defaultValue) =>
        string.IsNullOrEmpty(Env(name)) ? defaultValue : Env(name);

    public static int EnvInt(string name, int defaultValue) =>
        int.TryParse(Env(name), out int value) ? value : defaultValue;

    public static string EndpointUrl() => EnvOr("AWS_ENDPOINT_URL", "");

    public static string Region() => EnvOr("AWS_REGION", "us-east-1");

    public static string InputBucket() => EnvOr("INPUT_BUCKET", "streamvideo-input");

    public static string OutputBucket() => EnvOr("OUTPUT_BUCKET", "streamvideo-output");

    public static string JobsTable() => EnvOr("JOBS_TABLE", "streamvideo-jobs");

    public static string NotifyQueue() => EnvOr("NOTIFY_QUEUE", "streamvideo-notifications");

    public static string NotifyTopic() => EnvOr("NOTIFY_TOPIC", "streamvideo-notifications");

    public static string AnalyzerDriver() => EnvOr("ANALYZER", "local");

    public static string TranscoderDriver() => EnvOr("TRANSCODER", "stub");

    public static string AccessKey() => Env("AWS_ACCESS_KEY_ID");

    public static string SecretKey() => Env("AWS_SECRET_ACCESS_KEY");

    public static bool IsCloud() => string.IsNullOrEmpty(EndpointUrl());
}