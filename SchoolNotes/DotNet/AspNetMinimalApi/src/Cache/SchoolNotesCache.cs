using System.Text.Json;
using System.Threading.Tasks;

static class SchoolNotesCache
{
    public static string EntityPrefix(string entity)
        => $"schoolnotes:{entity}:";

    public static string ListKey(string entity, int page, int pageSize)
        => $"{EntityPrefix(entity)}page:{page}:size:{pageSize}";

    public static string DetailKey(string entity, int id)
        => $"{EntityPrefix(entity)}id:{id}";

    public static async Task InvalidateEntityAsync(ICacheAdapter cache, string entity)
    {
        await cache.RemoveByPrefixAsync(EntityPrefix(entity));
    }

    public static async Task SetListAsync<T>(ICacheAdapter cache, string entity, int page, int pageSize, List<T> data)
    {
        await cache.SetAsync(ListKey(entity, page, pageSize), JsonSerializer.Serialize(data), 300);
    }

    public static async Task SetDetailAsync<T>(ICacheAdapter cache, string entity, int id, T item)
    {
        await cache.SetAsync(DetailKey(entity, id), JsonSerializer.Serialize(item), 300);
    }
}
