public interface IChatProvider
{
    Task<ChatResponse> CompleteAsync(ChatRequest request);
}
