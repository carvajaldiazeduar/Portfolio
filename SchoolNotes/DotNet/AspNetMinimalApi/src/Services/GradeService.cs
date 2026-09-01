class GradeService : CrudService<Grade>
{
    public GradeService(SchoolNotesDbContext db) : base(db) { }
    public override Dictionary<string, string> Validate(Grade entity) => Validators.Grade(entity);
}
