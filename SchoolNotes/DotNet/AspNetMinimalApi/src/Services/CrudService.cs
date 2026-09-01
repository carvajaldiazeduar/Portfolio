using System.Collections.Generic;

abstract class CrudService<T> where T : class, IEntity, new()
{
    protected readonly SchoolNotesDbContext _db;

    public CrudService(SchoolNotesDbContext db)
    {
        _db = db;
    }

    public virtual Dictionary<string, string> Validate(T entity) => new Dictionary<string, string>();
    public virtual Dictionary<string, string> ValidateCreate(T entity) => new Dictionary<string, string>();
    public virtual Dictionary<string, string> ValidateUpdate(int id, T entity) => new Dictionary<string, string>();
    public virtual int CountDependents(int id) => 0;

    public List<T> List(int page, int size)
    {
        return _db.Set<T>().Skip((page - 1) * size).Take(size).ToList();
    }

    public T Get(int id)
    {
        return _db.Set<T>().Find(id);
    }

    public T Create(T entity)
    {
        _db.Set<T>().Add(entity);
        _db.SaveChanges();
        return entity;
    }

    public T Update(int id, T entity)
    {
        T existing = _db.Set<T>().Find(id);
        if (existing == null)
            return null;

        _db.Entry(existing).CurrentValues.SetValues(entity);
        _db.SaveChanges();
        return existing;
    }

    public (bool ok, string message) Delete(int id)
    {
        int dependents = CountDependents(id);
        if (dependents > 0)
            return (false, "This record cannot be deleted because other records are dependent on it.");

        T existing = _db.Set<T>().Find(id);
        if (existing == null)
            return (false, "Not found");

        _db.Set<T>().Remove(existing);
        _db.SaveChanges();

        return (true, null);
    }
}
