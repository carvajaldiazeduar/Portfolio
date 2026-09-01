class EnrollmentService : CrudService<Enrollment>
{
    public EnrollmentService(SchoolNotesDbContext db) : base(db) { }
    public override Dictionary<string, string> Validate(Enrollment entity) => Validators.Enrollment(entity);

    public override Dictionary<string, string> ValidateCreate(Enrollment entity)
    {
        Dictionary<string, string> errors = new Dictionary<string, string>();
        if (_db.Enrollments.Any(e => e.StudentId == entity.StudentId && e.CourseId == entity.CourseId && e.PeriodId == entity.PeriodId))
            errors["Enrollment"] = "A record with this combination of student, course and period already exists.";

        return errors;
    }

    public override Dictionary<string, string> ValidateUpdate(int id, Enrollment entity)
    {
        Dictionary<string, string> errors = new Dictionary<string, string>();
        if (_db.Enrollments.Any(e => e.StudentId == entity.StudentId && e.CourseId == entity.CourseId && e.PeriodId == entity.PeriodId && e.Id != id))
            errors["Enrollment"] = "A record with this combination of student, course and period already exists.";

        return errors;
    }
}
