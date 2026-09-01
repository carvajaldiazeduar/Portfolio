using System.Threading.Tasks;
using Xunit;

namespace SchoolNotes.Tests;

public class CacheTests
{
    [Fact]
    public async Task LocalCache_Set_Get()
    {
        LocalCache cache = new LocalCache();
        await cache.SetAsync("k", "v", 60);
        Assert.Equal("v", await cache.GetAsync("k"));
    }

    [Fact]
    public async Task LocalCache_Missing_Returns_Null()
    {
        LocalCache cache = new LocalCache();
        Assert.Null(await cache.GetAsync("missing"));
    }

    [Fact]
    public async Task LocalCache_Increment_Grows()
    {
        LocalCache cache = new LocalCache();
        Assert.Equal(1, await cache.IncrementAsync("r", 60));
        Assert.Equal(2, await cache.IncrementAsync("r", 60));
        Assert.Equal(3, await cache.IncrementAsync("r", 60));
    }

    [Fact]
    public async Task LocalCache_Increment_AfterSeed_AdvancesPastSeed()
    {
        LocalCache cache = new LocalCache();
        await cache.SetAsync("ver:students", "1", 300);
        Assert.Equal(2, await cache.IncrementAsync("ver:students", 300));
    }

    [Fact]
    public async Task LocalCache_RemoveByPrefix_OnlyClearsMatchingEntity()
    {
        LocalCache cache = new LocalCache();
        await cache.SetAsync("schoolnotes:students:id:42", "student", 60);
        await cache.SetAsync("schoolnotes:students:page:1:size:10", "students", 60);
        await cache.SetAsync("schoolnotes:teachers:id:7", "teacher", 60);

        await cache.RemoveByPrefixAsync("schoolnotes:students:");

        Assert.Null(await cache.GetAsync("schoolnotes:students:id:42"));
        Assert.Null(await cache.GetAsync("schoolnotes:students:page:1:size:10"));
        Assert.Equal("teacher", await cache.GetAsync("schoolnotes:teachers:id:7"));
    }

    [Fact]
    public void SchoolNotesCache_Builds_EntitySpecific_Keys()
    {
        Assert.Equal("schoolnotes:students:", SchoolNotesCache.EntityPrefix("students"));
        Assert.Equal("schoolnotes:students:page:2:size:20", SchoolNotesCache.ListKey("students", 2, 20));
        Assert.Equal("schoolnotes:students:id:42", SchoolNotesCache.DetailKey("students", 42));
    }
}
