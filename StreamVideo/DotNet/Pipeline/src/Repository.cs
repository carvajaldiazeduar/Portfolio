using System.Globalization;
using System.Text.Json;
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;

namespace StreamVideo;

/// <summary>Job state repository (DynamoDB) behind a driver interface.</summary>
public interface IJobRepository
{
    Task EnsureTableAsync(CancellationToken ct = default);
    Task CreateJobAsync(string videoKey, CancellationToken ct = default);
    Task UpdateJobAsync(string videoKey, IReadOnlyDictionary<string, object?> fields, CancellationToken ct = default);
    Task<Dictionary<string, object?>?> GetJobAsync(string videoKey, CancellationToken ct = default);
}

/// <summary>DynamoDB implementation; single global index keyed on the video key.</summary>
public sealed class DynamoDbJobRepository : IJobRepository
{
    private readonly AmazonDynamoDBClient _client;

    public string TableName { get; }

    public DynamoDbJobRepository(AmazonDynamoDBClient client, string tableName)
    {
        _client = client;
        TableName = tableName;
    }

    private static AttributeValue Attr(object? value) => value switch
    {
        bool b => new AttributeValue { BOOL = b },
        int i => new AttributeValue { N = i.ToString(CultureInfo.InvariantCulture) },
        long l => new AttributeValue { N = l.ToString(CultureInfo.InvariantCulture) },
        double d => new AttributeValue { N = d.ToString(CultureInfo.InvariantCulture) },
        _ when value is not string && value is System.Collections.IEnumerable =>
            new AttributeValue { S = JsonSerializer.Serialize(value) },
        _ => new AttributeValue { S = value?.ToString() ?? "" },
    };

    private static object? FromAttr(AttributeValue attr)
    {
        if (attr.S != null && attr.S.Length > 0)
        {
            string text = attr.S;
            if (text[0] == '[' || text[0] == '{')
            {
                try
                {
                    return JsonSerializer.Deserialize<object>(text);
                }
                catch (JsonException)
                {
                    return text;
                }
            }
            return text;
        }
        if (attr.N != null && attr.N.Length > 0)
        {
            return long.TryParse(attr.N, out long number) ? number : attr.N;
        }
        if (attr.IsBOOLSet)
        {
            return attr.BOOL;
        }
        return null;
    }

    public async Task EnsureTableAsync(CancellationToken ct = default)
    {
        try
        {
            await _client.DescribeTableAsync(TableName, ct);
            return;
        }
        catch (ResourceNotFoundException)
        {
            // fallthrough: create it
        }

        await _client.CreateTableAsync(
            new CreateTableRequest
            {
                TableName = TableName,
                KeySchema = { new KeySchemaElement("video_key", KeyType.HASH) },
                AttributeDefinitions = { new AttributeDefinition("video_key", ScalarAttributeType.S) },
                BillingMode = BillingMode.PAY_PER_REQUEST,
            },
            ct
        );

        for (int attempt = 0; attempt < 20; attempt++)
        {
            try
            {
                var response = await _client.DescribeTableAsync(TableName, ct);
                if (response.Table.TableStatus == TableStatus.ACTIVE)
                {
                    return;
                }
            }
            catch (ResourceNotFoundException)
            {
                // table not visible yet
            }
            await Task.Delay(TimeSpan.FromSeconds(1), ct);
        }
    }

    public Task CreateJobAsync(string videoKey, CancellationToken ct = default) =>
        _client.PutItemAsync(
            new PutItemRequest
            {
                TableName = TableName,
                Item = new Dictionary<string, AttributeValue>
                {
                    ["video_key"] = new AttributeValue { S = videoKey },
                    ["status"] = new AttributeValue { S = JobStatus.Processing },
                    ["created_at"] = new AttributeValue
                    {
                        N = DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString(CultureInfo.InvariantCulture),
                    },
                },
            },
            ct
        );

    public async Task UpdateJobAsync(
        string videoKey,
        IReadOnlyDictionary<string, object?> fields,
        CancellationToken ct = default
    )
    {
        var all = new Dictionary<string, object?>(fields)
        {
            ["updated_at"] = DateTimeOffset.UtcNow.ToUnixTimeSeconds(),
        };

        var names = new Dictionary<string, string>();
        var values = new Dictionary<string, AttributeValue>();
        var assignments = new List<string>();
        foreach ((string key, object? value) in all)
        {
            string name = $"#{key}";
            string placeholder = $":{key}";
            names[name] = key;
            values[placeholder] = Attr(value);
            assignments.Add($"{name} = {placeholder}");
        }

        await _client.UpdateItemAsync(
            new UpdateItemRequest
            {
                TableName = TableName,
                Key = new Dictionary<string, AttributeValue>
                {
                    ["video_key"] = new AttributeValue { S = videoKey },
                },
                UpdateExpression = $"SET {string.Join(", ", assignments)}",
                ExpressionAttributeNames = names,
                ExpressionAttributeValues = values,
            },
            ct
        );
    }

    public async Task<Dictionary<string, object?>?> GetJobAsync(string videoKey, CancellationToken ct = default)
    {
        var response = await _client.GetItemAsync(
            new GetItemRequest
            {
                TableName = TableName,
                Key = new Dictionary<string, AttributeValue>
                {
                    ["video_key"] = new AttributeValue { S = videoKey },
                },
            },
            ct
        );

        if (response.Item is null || response.Item.Count == 0)
        {
            return null;
        }
        return response.Item.ToDictionary(kv => kv.Key, kv => FromAttr(kv.Value));
    }
}