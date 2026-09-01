using Microsoft.EntityFrameworkCore;

public class PasswordEntry
{
    public int Id { get; set; }
    public string Password { get; set; } = "";
    public int Length { get; set; }
    public string CreatedAt { get; set; } = "";
}

public class PasswordGeneratorDbContext : DbContext
{
    public DbSet<PasswordEntry> PasswordEntries { get; set; } = null!;

    public PasswordGeneratorDbContext(DbContextOptions<PasswordGeneratorDbContext> options) : base(options) { }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        var entity = modelBuilder.Entity<PasswordEntry>();
        entity.ToTable("password_entries");
        entity.HasKey(p => p.Id);
        entity.Property(p => p.Id).HasColumnName("id");
        entity.Property(p => p.Password).HasColumnName("password");
        entity.Property(p => p.Length).HasColumnName("length");
        entity.Property(p => p.CreatedAt).HasColumnName("created_at");
        entity.Property(p => p.Id).ValueGeneratedOnAdd();
    }
}