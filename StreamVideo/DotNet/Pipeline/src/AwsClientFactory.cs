using Amazon;
using Amazon.DynamoDBv2;
using Amazon.Rekognition;
using Amazon.Runtime;
using Amazon.S3;
using Amazon.SimpleNotificationService;
using Amazon.SQS;

namespace StreamVideo;

/// <summary>boto3-like client factory aware of AWS_ENDPOINT_URL (LocalStack / AWS).</summary>
public static class AwsClientFactory
{
    private static readonly AWSCredentials Credentials;

    static AwsClientFactory()
    {
        string access = Config.AccessKey();
        string secret = Config.SecretKey();
        Credentials = access.Length > 0 && secret.Length > 0
            ? new BasicAWSCredentials(access, secret)
            : new AnonymousAWSCredentials();
    }

    private static T WithEndpoint<T>(T config) where T : ClientConfig
    {
        string endpoint = Config.EndpointUrl();
        if (endpoint.Length == 0)
        {
            config.RegionEndpoint = RegionEndpoint.GetBySystemName(Config.Region());
        }
        else
        {
            config.ServiceURL = endpoint;
        }
        return config;
    }

    public static AmazonS3Client S3()
    {
        var config = WithEndpoint(new AmazonS3Config());
        if (Config.EndpointUrl().Length > 0)
        {
            config.ForcePathStyle = true;
        }
        return new AmazonS3Client(Credentials, config);
    }

    public static AmazonDynamoDBClient DynamoDb() =>
        new(Credentials, WithEndpoint(new AmazonDynamoDBConfig()));

    public static AmazonSQSClient Sqs() =>
        new(Credentials, WithEndpoint(new AmazonSQSConfig()));

    public static AmazonSimpleNotificationServiceClient Sns() =>
        new(Credentials, WithEndpoint(new AmazonSimpleNotificationServiceConfig()));

    public static AmazonRekognitionClient Rekognition() =>
        new(Credentials, WithEndpoint(new AmazonRekognitionConfig()));
}