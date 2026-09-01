class StudentService : CrudService<Student>
{
    public StudentService(SchoolNotesDbContext db) : base(db) { }
    public override Dictionary<string, string> Validate(Student entity) => Validators.Student(entity);
    public override int CountDependents(int id) => _db.Enrollments.Count(x => x.StudentId == id);

    public override Dictionary<string, string> ValidateCreate(Student entity)
    {
        Dictionary<string, string> errors = new Dictionary<string, string>();
        if (_db.Students.Any(s => s.Code == entity.Code))
            errors["Code"] = "A record with this code already exists. Please use a different one.";

        return errors;
    }

    public override Dictionary<string, string> ValidateUpdate(int id, Student entity)
    {
        Dictionary<string, string> errors = new Dictionary<string, string>();
        if (_db.Students.Any(s => s.Code == entity.Code && s.Id != id))
            errors["Code"] = "A record with this code already exists. Please use a different one.";

        return errors;
    }
}
