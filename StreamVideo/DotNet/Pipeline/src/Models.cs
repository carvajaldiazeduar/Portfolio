namespace StreamVideo;

public static class JobStatus
{
    public const string Processing = "PROCESSING";
    public const string Completed = "COMPLETED";
    public const string Failed = "FAILED";
}

public sealed record VideoObject(string Bucket, string Key, long Size)
{
    public string Name => Key.Substring(Key.LastIndexOf('/') + 1);
}