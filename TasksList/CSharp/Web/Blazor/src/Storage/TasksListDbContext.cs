using Microsoft.EntityFrameworkCore;

public class TaskItem
{
    public int Id { get; set; }
    public string Title { get; set; } = "";
    public string Description { get; set; } = "";
    public bool Completed { get; set; }
    public string CreatedAt { get; set; } = "";
}

public class TasksListDbContext : DbContext
{
    public DbSet<TaskItem> Tasks { get; set; } = null!;

    public TasksListDbContext(DbContextOptions<TasksListDbContext> options) : base(options) { }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        var entity = modelBuilder.Entity<TaskItem>();
        entity.ToTable("tasks");
        entity.HasKey(t => t.Id);
        entity.Property(t => t.Id).HasColumnName("id");
        entity.Property(t => t.Title).HasColumnName("title");
        entity.Property(t => t.Description).HasColumnName("description");
        entity.Property(t => t.Completed).HasColumnName("completed");
        entity.Property(t => t.CreatedAt).HasColumnName("created_at");
        entity.Property(t => t.Id).ValueGeneratedOnAdd();
    }
}