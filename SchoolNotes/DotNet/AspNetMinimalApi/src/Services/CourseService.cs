class CourseService : CrudService<Course>
{
    public CourseService(SchoolNotesDbContext db) : base(db) { }
    public override Dictionary<string, string> Validate(Course entity) => Validators.Course(entity);
    public override int CountDependents(int id) => _db.Enrollments.Count(x => x.CourseId == id);
}
