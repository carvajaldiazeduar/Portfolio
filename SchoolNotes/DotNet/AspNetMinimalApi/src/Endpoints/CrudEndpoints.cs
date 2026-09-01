using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

static class CrudEndpoints
{
    public static void MapEntity<T>(
        this IEndpointRouteBuilder group,
        string entity,
        Func<SchoolNotesDbContext, CrudService<T>> factory
    ) where T : class, IEntity, new()
    {
        group.MapGet(entity, async (SchoolNotesDbContext db, ICacheAdapter cache, int page = 1, int pageSize = 10) =>
        {
            pageSize = Math.Clamp(pageSize, 1, 100);
            page = Math.Max(1, page);

            string key = SchoolNotesCache.ListKey(entity, page, pageSize);
            string cached = await cache.GetAsync(key);

            if (cached != null)
            {
                try
                {
                    List<T> list = JsonSerializer.Deserialize<List<T>>(cached);
                    if (list != null)
                        return Results.Ok(list);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Error occurred while deserializing cached data for {key}: {ex.Message}");
                }
            }

            List<T> data = factory(db).List(page, pageSize);
            await SchoolNotesCache.SetListAsync(cache, entity, page, pageSize, data);
            return Results.Ok(data);
        });

        group.MapGet(entity + "/{id:int}", async (int id, SchoolNotesDbContext db, ICacheAdapter cache) =>
        {
            string detailKey = SchoolNotesCache.DetailKey(entity, id);
            string cachedDetail = await cache.GetAsync(detailKey);
            
            if (cachedDetail != null)
            {
                try
                {
                    T item = JsonSerializer.Deserialize<T>(cachedDetail);
                    if (item != null)
                        return Results.Ok(item);
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Error occurred while deserializing cached data for {detailKey}: {ex.Message}");
                }
            }
            
            T fetched = factory(db).Get(id);
            if (fetched == null)
                return Results.NotFound();
            
            await SchoolNotesCache.SetDetailAsync(cache, entity, id, fetched);
            return Results.Ok(fetched);
        });

        group.MapPost(entity, async (T body, SchoolNotesDbContext db, ICacheAdapter cache) =>
        {
            CrudService<T> service = factory(db);
            Dictionary<string, string> errors = service.Validate(body);
            if (errors.Count > 0)
                return Results.BadRequest(new { errors });

            Dictionary<string, string> createErrors = service.ValidateCreate(body);
            if (createErrors.Count > 0)
                return Results.BadRequest(new { errors = createErrors });

try
            {
                T created = service.Create(body);
                await cache.IncrementAsync("ver:" + entity, 300);
                return Results.Created($"/api/{entity}/{created.Id}", created);
            }
            catch (DbUpdateException)
            {
                return Results.Conflict(new { error = "This operation conflicts with existing data. Please check for duplicate values or records that depend on this one." });
            }
        });

        group.MapPut(entity + "/{id:int}", async (int id, T body, SchoolNotesDbContext db, ICacheAdapter cache) =>
        {
            CrudService<T> service = factory(db);
            Dictionary<string, string> errors = service.Validate(body);
            if (errors.Count > 0)
                return Results.BadRequest(new { errors });

            Dictionary<string, string> updateErrors = service.ValidateUpdate(id, body);
            if (updateErrors.Count > 0)
                return Results.BadRequest(new { errors = updateErrors });

            body.Id = id;
            T updated = service.Update(id, body);
            if (updated == null)
                return Results.NotFound();

            await SchoolNotesCache.InvalidateEntityAsync(cache, entity);
            return Results.Ok(updated);
        });

        group.MapDelete(entity + "/{id:int}", async (int id, SchoolNotesDbContext db, ICacheAdapter cache) =>
        {
            (bool ok, string message) = factory(db).Delete(id);
            if (!ok)
                return Results.Conflict(new { error = message });

            await SchoolNotesCache.InvalidateEntityAsync(cache, entity);
            return Results.NoContent();
        });
    }

    public static void MapSchoolNotesEndpoints(this IEndpointRouteBuilder group)
    {
        group.MapEntity<Student>("students", db => new StudentService(db));
        group.MapEntity<Teacher>("teachers", db => new TeacherService(db));
        group.MapEntity<Course>("courses", db => new CourseService(db));
        group.MapEntity<Period>("periods", db => new PeriodService(db));
        group.MapEntity<Enrollment>("enrollments", db => new EnrollmentService(db));
        group.MapEntity<Grade>("grades", db => new GradeService(db));
    }
}
