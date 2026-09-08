using Amazon.S3;
using Amazon.S3.Model;

namespace StreamVideo;

/// <summary>Video storage adapter (S3) behind a driver interface.</summary>
public interface IVideoStorage
{
    Task EnsureStorageAsync(CancellationToken ct = default);
    Task<bool> ExistsAsync(string key, CancellationToken ct = default);
    Task PutAsync(string key, byte[] data, CancellationToken ct = default);
    Task<byte[]> GetAsync(string key, CancellationToken ct = default);
    Task<long> SizeOfAsync(string key, CancellationToken ct = default);
    Task<IReadOnlyDictionary<string, string>> MetadataAsync(string key, CancellationToken ct = default);
    Task<IReadOnlyList<string>> ListAsync(string prefix, CancellationToken ct = default);
    Task CopyAsync(string srcKey, string dstKey, CancellationToken ct = default);
    string PublicUrl(string key);
}

/// <summary>S3-backed implementation usable with real AWS or LocalStack.</summary>
public sealed class S3VideoStorage : IVideoStorage
{
    private readonly AmazonS3Client _client;
    private readonly string _inputBucket;
    private readonly string _outputBucket;

    public string InputBucket => _inputBucket;
    public string OutputBucket => _outputBucket;

    public S3VideoStorage(AmazonS3Client client, string inputBucket, string outputBucket)
    {
        _client = client;
        _inputBucket = inputBucket;
        _outputBucket = outputBucket;
    }

    public async Task EnsureStorageAsync(CancellationToken ct = default)
    {
        foreach (string bucket in new[] { _inputBucket, _outputBucket })
        {
            try
            {
                await _client.HeadBucketAsync(new HeadBucketRequest { BucketName = bucket }, ct);
            }
            catch (AmazonS3Exception)
            {
                await _client.PutBucketAsync(new PutBucketRequest { BucketName = bucket }, ct);
            }
        }

        // Browser (Vue web client) uploads to the input bucket; CORS is a demo
        // convenience and should not block a real deployment if it cannot be set.
        try
        {
            await _client.PutCORSConfigurationAsync(
                _inputBucket,
                new CORSConfiguration
                {
                    Rules =
                    {
                        new CORSRule
                        {
                            AllowedOrigins = { "*" },
                            AllowedMethods = { "GET", "PUT", "POST", "HEAD" },
                            AllowedHeaders = { "*" },
                            ExposeHeaders = { "ETag" },
                            MaxAgeSeconds = 3600,
                        }
                    }
                },
                ct
            );
        }
        catch (AmazonS3Exception)
        {
            // CORS setup is best-effort for the local web demo.
        }
    }

    public async Task<bool> ExistsAsync(string key, CancellationToken ct = default)
    {
        try
        {
            await _client.GetObjectMetadataAsync(_inputBucket, key, ct);
            return true;
        }
        catch (AmazonS3Exception)
        {
            return false;
        }
    }

    public Task PutAsync(string key, byte[] data, CancellationToken ct = default) =>
        _client.PutObjectAsync(
            new PutObjectRequest
            {
                BucketName = _inputBucket,
                Key = key,
                InputStream = new MemoryStream(data),
            },
            ct
        );

    public async Task<byte[]> GetAsync(string key, CancellationToken ct = default)
    {
        using GetObjectResponse response = await _client.GetObjectAsync(
            new GetObjectRequest { BucketName = _inputBucket, Key = key },
            ct
        );
        using MemoryStream buffer = new();
        await response.ResponseStream.CopyToAsync(buffer, ct);
        return buffer.ToArray();
    }

    public async Task<long> SizeOfAsync(string key, CancellationToken ct = default)
    {
        GetObjectMetadataResponse response = await _client.GetObjectMetadataAsync(_inputBucket, key, ct);
        return response.ContentLength;
    }

    public async Task<IReadOnlyDictionary<string, string>> MetadataAsync(string key, CancellationToken ct = default)
    {
        GetObjectMetadataResponse response = await _client.GetObjectMetadataAsync(_inputBucket, key, ct);
        Dictionary<string, string> metadata = new();
        foreach (string name in response.Metadata.Keys)
        {
            metadata[name] = response.Metadata[name];
        }
        return metadata;
    }

    public Task CopyAsync(string srcKey, string dstKey, CancellationToken ct = default) =>
        _client.CopyObjectAsync(_inputBucket, srcKey, _outputBucket, dstKey, ct);

    public async Task<IReadOnlyList<string>> ListAsync(string prefix, CancellationToken ct = default)
    {
        List<string> keys = new();
        string? continuationToken = null;
        do
        {
            ListObjectsV2Request request = new()
            {
                BucketName = _inputBucket,
                Prefix = prefix,
                ContinuationToken = continuationToken,
            };
            ListObjectsV2Response response = await _client.ListObjectsV2Async(request, ct);
            if (response.S3Objects != null)
            {
                keys.AddRange(response.S3Objects.Select(x => x.Key));
            }
            continuationToken = response.IsTruncated ? response.NextContinuationToken : null;
        }
        while (continuationToken != null);
        return keys;
    }

    public string PublicUrl(string key) => $"s3://{_outputBucket}/{key}";
}