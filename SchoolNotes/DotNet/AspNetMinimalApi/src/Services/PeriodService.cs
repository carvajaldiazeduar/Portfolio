class PeriodService : CrudService<Period>
{
    public PeriodService(SchoolNotesDbContext db) : base(db) { }
    public override Dictionary<string, string> Validate(Period entity) => Validators.Period(entity);
    public override int CountDependents(int id) => _db.Enrollments.Count(x => x.PeriodId == id);
}
