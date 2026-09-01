public class Enrollment : IEntity
{
    public int Id { get; set; }
    public int StudentId { get; set; }
    public int CourseId { get; set; }
    public int PeriodId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
