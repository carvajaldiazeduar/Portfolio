using System.Threading.Tasks;

interface ICacheAdapter
{
    Task<string> GetAsync(string key);
    Task SetAsync(string key, string value, int ttlSeconds);
    Task RemoveAsync(string key);
    Task<long> IncrementAsync(string key, int ttlSeconds);
    Task ClearAsync();
}