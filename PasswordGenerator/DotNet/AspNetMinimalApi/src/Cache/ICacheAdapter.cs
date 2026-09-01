public interface ICacheAdapter
{
    string? Get(string key);
    void Set(string key, string value, int ttl = 300);
    void Delete(string key);
}
