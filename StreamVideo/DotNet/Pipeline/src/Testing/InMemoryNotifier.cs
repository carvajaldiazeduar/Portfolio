using System.Text.Json;

namespace StreamVideo.Testing;

/// <summary>In-memory notifier double for local tests (mirrors SQS => SNS driver contract).</summary>
public sealed class InMemoryNotifier : INotifier
{
    private readonly List<string> _messages = new();
    public int Delivered { get; private set; }
    public IReadOnlyList<string> Messages => _messages;

    public Task EnsureResourcesAsync(CancellationToken ct = default) => Task.CompletedTask;

    public Task SendAsync(Dictionary<string, object?> eventData, CancellationToken ct = default)
    {
        _messages.Add(JsonSerializer.Serialize(eventData));
        return Task.CompletedTask;
    }

    public Task<int> ConsumeOnceAsync(
        Func<Dictionary<string, object?>, Task> publish,
        CancellationToken ct = default
    )
    {
        int handled = 0;
        while (_messages.Count > 0)
        {
            string body = _messages[0];
            _messages.RemoveAt(0);
            var eventData = JsonSerializer.Deserialize<Dictionary<string, object?>>(body) ?? new();
            publish(eventData).GetAwaiter().GetResult();
            Delivered++;
            handled++;
            ct.ThrowIfCancellationRequested();
        }
        return Task.FromResult(handled);
    }
}