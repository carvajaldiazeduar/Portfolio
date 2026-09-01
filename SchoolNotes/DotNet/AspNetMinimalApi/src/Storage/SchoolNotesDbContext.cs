using Microsoft.EntityFrameworkCore;

public class SchoolNotesDbContext : DbContext
{
    public DbSet<User> Users { get; set; }
    public DbSet<Student> Students { get; set; }
    public DbSet<Teacher> Teachers { get; set; }
    public DbSet<Course> Courses { get; set; }
    public DbSet<Period> Periods { get; set; }
    public DbSet<Enrollment> Enrollments { get; set; }
    public DbSet<Grade> Grades { get; set; }

    public SchoolNotesDbContext(DbContextOptions<SchoolNotesDbContext> options) : base(options) { }
    public SchoolNotesDbContext(DbContextOptions options) : base(options) { }
    // Parameterless constructor for tests convenience - uses an in-memory provider
    public SchoolNotesDbContext() : base(new DbContextOptionsBuilder<SchoolNotesDbContext>().UseInMemoryDatabase(System.Guid.NewGuid().ToString()).Options) { }

    protected override void OnModelCreating(ModelBuilder model)
    {
        model.Entity<User>().HasIndex(u => u.Username).IsUnique();
        model.Entity<Student>().HasIndex(s => s.Code).IsUnique();
        model.Entity<Teacher>().HasIndex(t => t.Code).IsUnique();
        model.Entity<Enrollment>().HasIndex(e => new { e.StudentId, e.CourseId, e.PeriodId }).IsUnique();

        model.Entity<User>().Property(u => u.Username).HasMaxLength(50);
        model.Entity<User>().Property(u => u.PasswordHash).HasMaxLength(255);
        model.Entity<User>().Property(u => u.Role).HasMaxLength(20);
        model.Entity<Student>().Property(s => s.FirstName).HasMaxLength(100);
        model.Entity<Student>().Property(s => s.LastName).HasMaxLength(100);
        model.Entity<Student>().Property(s => s.Code).HasMaxLength(20);
        model.Entity<Student>().Property(s => s.Email).HasMaxLength(200);
        model.Entity<Teacher>().Property(t => t.FirstName).HasMaxLength(100);
        model.Entity<Teacher>().Property(t => t.LastName).HasMaxLength(100);
        model.Entity<Teacher>().Property(t => t.Code).HasMaxLength(20);
        model.Entity<Teacher>().Property(t => t.Email).HasMaxLength(200);
        model.Entity<Course>().Property(c => c.Name).HasMaxLength(150);
        model.Entity<Period>().Property(p => p.Name).HasMaxLength(50);
        model.Entity<Grade>().Property(g => g.Label).HasMaxLength(100);
        model.Entity<Grade>().Property(g => g.Observation).HasMaxLength(500);

        model.Entity<Course>().HasOne<Teacher>().WithMany().HasForeignKey(c => c.TeacherId).OnDelete(DeleteBehavior.Restrict);
        model.Entity<Enrollment>().HasOne<Student>().WithMany().HasForeignKey(e => e.StudentId).OnDelete(DeleteBehavior.Restrict);
        model.Entity<Enrollment>().HasOne<Course>().WithMany().HasForeignKey(e => e.CourseId).OnDelete(DeleteBehavior.Restrict);
        model.Entity<Enrollment>().HasOne<Period>().WithMany().HasForeignKey(e => e.PeriodId).OnDelete(DeleteBehavior.Restrict);
        model.Entity<Grade>().HasOne<Enrollment>().WithMany().HasForeignKey(g => g.EnrollmentId).OnDelete(DeleteBehavior.Cascade);
    }
}
