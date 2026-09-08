using System.Text.Json;
using Amazon.SimpleNotificationService;
using Amazon.SimpleNotificationService.Model;
using Amazon.SQS;
using Amazon.SQS.Model;

namespace StreamVideo;

/// <summary>Notification adapter: SQS buffers the completion event, SNS delivers it.</summary>
public interface INotifier
{
    Task EnsureResourcesAsync(CancellationToken ct = default);
    Task SendAsync(Dictionary<string, object?> eventData, CancellationToken ct = default);
    Task<int> ConsumeOnceAsync(Func<Dictionary<string, object?>, Task> publish, CancellationToken ct = default);
}

/// <summary>SQS => SNS drain loop. In AWS the real worker is the notify Lambda (CDK).</summary>
public sealed class SqsSnsNotifier : INotifier
{
    private readonly AmazonSQSClient _sqs;
    private readonly AmazonSimpleNotificationServiceClient _sns;
    private readonly string _queueName;
    private readonly string _topicName;

    public AmazonSQSClient Sqs => _sqs;
    public AmazonSimpleNotificationServiceClient Sns => _sns;
    public string QueueName => _queueName;
    public string TopicName => _topicName;
    public string QueueUrl { get; private set; } = "";
    public string TopicArn { get; private set; } = "";
    public int Delivered { get; private set; }

    public SqsSnsNotifier(AmazonSQSClient sqs, AmazonSimpleNotificationServiceClient sns, string queueName, string topicName)
    {
        _sqs = sqs;
        _sns = sns;
        _queueName = queueName;
        _topicName = topicName;
    }

    public async Task EnsureResourcesAsync(CancellationToken ct = default)
    {
        QueueUrl = (await _sqs.CreateQueueAsync(_queueName, ct)).QueueUrl;
        TopicArn = (await _sns.CreateTopicAsync(_topicName, ct)).TopicArn;
    }

    public async Task SendAsync(Dictionary<string, object?> eventData, CancellationToken ct = default)
    {
        if (QueueUrl.Length == 0)
        {
            throw new InvalidOperationException("Notifier resources not initialized");
        }
        await _sqs.SendMessageAsync(QueueUrl, JsonSerializer.Serialize(eventData), ct);
    }

    public async Task<int> ConsumeOnceAsync(
        Func<Dictionary<string, object?>, Task> publish,
        CancellationToken ct = default
    )
    {
        if (QueueUrl.Length == 0)
        {
            throw new InvalidOperationException("Notifier resources not initialized");
        }

        var response = await _sqs.ReceiveMessageAsync(
            new ReceiveMessageRequest
            {
                QueueUrl = QueueUrl,
                MaxNumberOfMessages = 10,
                WaitTimeSeconds = 1,
                VisibilityTimeout = 30,
            },
            ct
        );

        int handled = 0;
        foreach (Message message in response.Messages)
        {
            try
            {
                var eventData = JsonSerializer.Deserialize<Dictionary<string, object?>>(message.Body) ?? new();
                await publish(eventData);
                Delivered++;
            }
            catch (Exception)
            {
                // mirror Python's log.exception("Failed to deliver notification")
            }
            finally
            {
                await _sqs.DeleteMessageAsync(QueueUrl, message.ReceiptHandle, ct);
                handled++;
            }
        }
        return handled;
    }
}

/// <summary>Builder for the SNS publish delegate used by the runner.</summary>
public static class SnsPublisher
{
    public static Func<Dictionary<string, object?>, Task> For(
        AmazonSimpleNotificationServiceClient sns,
        string topicArn
    ) =>
        async eventData =>
        {
            await sns.PublishAsync(
                new PublishRequest
                {
                    TopicArn = topicArn,
                    Subject = "video-ready",
                    Message = JsonSerializer.Serialize(eventData),
                }
            );
        };
}