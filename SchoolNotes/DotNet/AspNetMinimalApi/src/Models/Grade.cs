public class Grade : IEntity
{
    public int Id { get; set; }
    public int EnrollmentId { get; set; }
    public string Label { get; set; }
    public decimal Score { get; set; }
    public decimal MaxScore { get; set; } = 100;
    public string Observation { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
