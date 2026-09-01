class TeacherService : CrudService<Teacher>
{
    public TeacherService(SchoolNotesDbContext db) : base(db) { }
    public override Dictionary<string, string> Validate(Teacher entity) => Validators.Teacher(entity);
    public override int CountDependents(int id) => _db.Courses.Count(x => x.TeacherId == id);

    public override Dictionary<string, string> ValidateCreate(Teacher entity)
    {
        Dictionary<string, string> errors = new Dictionary<string, string>();
        if (_db.Teachers.Any(t => t.Code == entity.Code))
            errors["Code"] = "A record with this code already exists. Please use a different one.";

        return errors;
    }

    public override Dictionary<string, string> ValidateUpdate(int id, Teacher entity)
    {
        Dictionary<string, string> errors = new Dictionary<string, string>();
        if (_db.Teachers.Any(t => t.Code == entity.Code && t.Id != id))
            errors["Code"] = "A record with this code already exists. Please use a different one.";

        return errors;
    }
}
