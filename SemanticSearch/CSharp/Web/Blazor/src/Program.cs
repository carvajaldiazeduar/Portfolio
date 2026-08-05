using System.Text.Json;
using Microsoft.AspNetCore.Components;
using SemanticSearchBlazor;

var driver = (Environment.GetEnvironmentVariable("DB_DRIVER") ?? "postgresql").ToLower();

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddRazorComponents().AddInteractiveServerComponents();
builder.Services.AddSingleton<VectorStoreAdapter>(_ => CreateVectorStore());
builder.Services.AddSingleton<CacheAdapter>(_ => CreateCache());

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseAntiforgery();

app.MapRazorComponents<App>().AddInteractiveServerRenderMode();
app.Run();

VectorStoreAdapter CreateVectorStore()
{
    var driver = Environment.GetEnvironmentVariable("VECTOR_DRIVER") ?? "chromadb";
    return driver switch
    {
        "pinecone" => new PineconeAdapter(),
        "pgvector" => new PgVectorAdapter(),
        _ => new ChromaDBAdapter(),
    };
}

CacheAdapter CreateCache()
{
    try
    {
        return new RedisCache();
    }
    catch
    {
        return new LocalCache();
    }
}

public abstract class VectorStoreAdapter
{
    public abstract Task Connect();
    public abstract Task AddDocuments(List<string> documents, List<float[]> embeddings, List<Dictionary<string, object>> metadata);
    public abstract Task<List<SearchResult>> Search(float[] queryEmbedding, int nResults = 5);
    public abstract Task DeleteCollection(string collectionName);
    public abstract List<string> ListCollections();
    public abstract Task Close();
}

public class SearchResult
{
    public string Document { get; set; } = "";
    public Dictionary<string, object>? Metadata { get; set; }
    public double Distance { get; set; }
}

public class ChromaDBAdapter : VectorStoreAdapter
{
    private object? _client;
    private readonly Dictionary<string, object> _collections = new();

    public override async Task Connect()
    {
        if (_client != null) return;
        var chroma = Type.GetType("ChromaDB.Client, ChromaDB") ?? throw new Exception("ChromaDB not available");
        _client = Activator.CreateInstance(chroma);
    }

    public override async Task AddDocuments(List<string> documents, List<float[]> embeddings, List<Dictionary<string, object>> metadata)
    {
        await Connect();
        var collectionName = Environment.GetEnvironmentVariable("VECTOR_COLLECTION") ?? "documents";
        if (!_collections.ContainsKey(collectionName))
        {
            _collections[collectionName] = _client!.GetType().GetMethod("GetOrCreateCollection")!.Invoke(_client, new object[] { collectionName });
        }
        var collection = _collections[collectionName];
        var ids = documents.Select((_, i) => $"doc_{i}").ToList();
        collection.GetType().GetMethod("Add")!.Invoke(collection, new object[] { documents, embeddings, metadata, ids });
    }

    public override async Task<List<SearchResult>> Search(float[] queryEmbedding, int nResults = 5)
    {
        await Connect();
        var collectionName = Environment.GetEnvironmentVariable("VECTOR_COLLECTION") ?? "documents";
        if (!_collections.ContainsKey(collectionName)) return new List<SearchResult>();
        var collection = _collections[collectionName];
        var results = collection.GetType().GetMethod("Query")!.Invoke(collection, new object[] { new[] { queryEmbedding }, nResults });
        var docs = results.GetType().GetProperty("Documents")!.GetValue(results) as System.Collections.IEnumerable;
        var metas = results.GetType().GetProperty("Metadatas")!.GetValue(results) as System.Collections.IEnumerable;
        var dists = results.GetType().GetProperty("Distances")!.GetValue(results) as System.Collections.IEnumerable;
        var resultList = new List<SearchResult>();
        var docEnum = docs!.GetEnumerator();
        var metaEnum = metas!.GetEnumerator();
        var distEnum = dists!.GetEnumerator();
        while (docEnum.MoveNext() && metaEnum.MoveNext() && distEnum.MoveNext())
        {
            resultList.Add(new SearchResult
            {
                Document = docEnum.Current?.ToString() ?? "",
                Metadata = metaEnum.Current as Dictionary<string, object>,
                Distance = Convert.ToDouble(distEnum.Current),
            });
        }
        return resultList;
    }

    public override async Task DeleteCollection(string collectionName)
    {
        _collections.Remove(collectionName);
        _client?.GetType().GetMethod("DeleteCollection")!.Invoke(_client, new object[] { collectionName });
    }

    public override List<string> ListCollections()
    {
        return _client?.GetType().GetMethod("ListCollections")!.Invoke(_client, null) is System.Collections.IEnumerable cols
            ? cols.Cast<object>().Select(c => c.ToString()!).ToList()
            : new List<string>();
    }

    public override async Task Close()
    {
        _collections.Clear();
        _client = null;
    }
}

public class PineconeAdapter : VectorStoreAdapter
{
    private object? _index;

    public override async Task Connect()
    {
        if (_index != null) return;
        var pinecone = Type.GetType("Pinecone.Pinecone, Pinecone") ?? throw new Exception("Pinecone not available");
        var apiKey = Environment.GetEnvironmentVariable("PINECONE_API_KEY") ?? "";
        var client = Activator.CreateInstance(pinecone, new object[] { apiKey });
        var indexName = Environment.GetEnvironmentVariable("PINECONE_INDEX") ?? "documents";
        _index = client.GetType().GetMethod("Index")!.Invoke(client, new object[] { indexName });
    }

    public override async Task AddDocuments(List<string> documents, List<float[]> embeddings, List<Dictionary<string, object>> metadata)
    {
        await Connect();
        var vectors = documents.Select((doc, i) => new
        {
            id = $"doc_{i}",
            values = embeddings[i],
            metadata = metadata[i],
        }).ToList();
        _index!.GetType().GetMethod("Upsert")!.Invoke(_index, new object[] { new { vectors } });
    }

    public override async Task<List<SearchResult>> Search(float[] queryEmbedding, int nResults = 5)
    {
        await Connect();
        var results = _index!.GetType().GetMethod("Query")!.Invoke(_index, new object[] { queryEmbedding, nResults, true });
        var matches = results.GetType().GetProperty("Matches")!.GetValue(results) as System.Collections.IEnumerable;
        return matches!.Cast<object>().Select(m =>
        {
            var meta = m.GetType().GetProperty("Metadata")!.GetValue(m) as Dictionary<string, object>;
            return new SearchResult
            {
                Document = meta?.ContainsKey("text") == true ? meta["text"]?.ToString() ?? "" : "",
                Metadata = meta,
                Distance = Convert.ToDouble(m.GetType().GetProperty("Score")!.GetValue(m)),
            };
        }).ToList();
    }

    public override async Task DeleteCollection(string collectionName) { }
    public override List<string> ListCollections() => new();
    public override async Task Close() { _index = null; }
}

public class PgVectorAdapter : VectorStoreAdapter
{
    private Npgsql.NpgsqlDataSource? _ds;

    public override async Task Connect()
    {
        if (_ds != null) return;
        var connStr = $"Host={Environment.GetEnvironmentVariable("DB_HOST") ?? "db"};Port={Environment.GetEnvironmentVariable("DB_PORT") ?? "5432"};Database={Environment.GetEnvironmentVariable("DB_NAME") ?? "semantic_search"};Username={Environment.GetEnvironmentVariable("DB_USER") ?? "postgres"};Password={Environment.GetEnvironmentVariable("DB_PASSWORD") ?? "postgres"}";
        _ds = Npgsql.NpgsqlDataSource.Create(connStr);
        await using var conn = await _ds.OpenConnectionAsync();
        await using var cmd = new Npgsql.NpgsqlCommand("CREATE EXTENSION IF NOT EXISTS vector", conn);
        await cmd.ExecuteNonQueryAsync();
    }

    public override async Task AddDocuments(List<string> documents, List<float[]> embeddings, List<Dictionary<string, object>> metadata)
    {
        await Connect();
        var collectionName = Environment.GetEnvironmentVariable("VECTOR_COLLECTION") ?? "documents";
        var table = $"vector_{collectionName.Replace('-', '_')}";
        await using var conn = await _ds!.OpenConnectionAsync();
        await using var cmd = new Npgsql.NpgsqlCommand($"CREATE TABLE IF NOT EXISTS {table} (id SERIAL PRIMARY KEY, document TEXT, embedding vector, metadata JSONB)", conn);
        await cmd.ExecuteNonQueryAsync();
        foreach (var (doc, emb, meta) in documents.Zip(embeddings).Zip(metadata, (x, m) => (x.First, x.Second, m)))
        {
            await using var cmd2 = new Npgsql.NpgsqlCommand($"INSERT INTO {table} (document, embedding, metadata) VALUES (@d, @e, @m)", conn);
            cmd2.Parameters.AddWithValue("d", doc);
            cmd2.Parameters.AddWithValue("e", emb);
            cmd2.Parameters.AddWithValue("m", JsonSerializer.Serialize(meta));
            await cmd2.ExecuteNonQueryAsync();
        }
    }

    public override async Task<List<SearchResult>> Search(float[] queryEmbedding, int nResults = 5)
    {
        await Connect();
        var collectionName = Environment.GetEnvironmentVariable("VECTOR_COLLECTION") ?? "documents";
        var table = $"vector_{collectionName.Replace('-', '_')}";
        await using var conn = await _ds!.OpenConnectionAsync();
        await using var cmd = new Npgsql.NpgsqlCommand($"SELECT document, metadata, embedding <=> @q::vector AS distance FROM {table} ORDER BY embedding <=> @q::vector LIMIT @n", conn);
        cmd.Parameters.AddWithValue("q", JsonSerializer.Serialize(queryEmbedding));
        cmd.Parameters.AddWithValue("n", nResults);
        var results = new List<SearchResult>();
        await using var reader = await cmd.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            results.Add(new SearchResult
            {
                Document = reader.GetString(0),
                Metadata = JsonSerializer.Deserialize<Dictionary<string, object>>(reader.GetString(1) ?? "{}"),
                Distance = reader.GetDouble(2),
            });
        }
        return results;
    }

    public override async Task DeleteCollection(string collectionName)
    {
        var table = $"vector_{collectionName.Replace('-', '_')}";
        await using var conn = await _ds!.OpenConnectionAsync();
        await using var cmd = new Npgsql.NpgsqlCommand($"DROP TABLE IF EXISTS {table}", conn);
        await cmd.ExecuteNonQueryAsync();
    }

    public override List<string> ListCollections() => new();
    public override async Task Close() { _ds = null; }
}

public class RedisCache : CacheAdapter
{
    private StackExchange.Redis.IConnectionMultiplexer? _redis;

    public RedisCache()
    {
        try
        {
            var redisHost = Environment.GetEnvironmentVariable("REDIS_HOST") ?? "localhost:6379";
            _redis = StackExchange.Redis.ConnectionMultiplexer.Connect(redisHost);
        }
        catch { }
    }

    public override string? Get(string key)
    {
        if (_redis == null) return null;
        try
        {
            var val = _redis.GetDatabase().StringGet(key);
            return val.HasValue ? val.ToString() : null;
        }
        catch { return null; }
    }

    public override void Set(string key, string value, int ttl = 300)
    {
        if (_redis == null) return;
        try { _redis.GetDatabase().StringSet(key, value, TimeSpan.FromSeconds(ttl)); } catch { }
    }

    public override void Delete(string key)
    {
        if (_redis == null) return;
        try { _redis.GetDatabase().KeyDelete(key); } catch { }
    }
}

public class LocalCache : CacheAdapter
{
    private readonly Dictionary<string, (string Value, DateTime Expiry)> _store = new();

    public override string? Get(string key)
    {
        if (_store.TryGetValue(key, out var entry) && entry.Expiry > DateTime.UtcNow)
            return entry.Value;
        _store.Remove(key);
        return null;
    }

    public override void Set(string key, string value, int ttl = 300)
    {
        _store[key] = (value, DateTime.UtcNow.AddSeconds(ttl));
    }

    public override void Delete(string key)
    {
        _store.Remove(key);
    }
}

public abstract class CacheAdapter
{
    public abstract string? Get(string key);
    public abstract void Set(string key, string value, int ttl = 300);
    public abstract void Delete(string key);
}
