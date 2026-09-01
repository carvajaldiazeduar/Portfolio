using System.Text.Json.Serialization;
using Microsoft.EntityFrameworkCore;

public class Message
{
    public int Id { get; set; }
    [JsonPropertyName("from")]
    public string Sender { get; set; } = "";
    public string Subject { get; set; } = "";
    public string Body { get; set; } = "";
    public bool Read { get; set; }
    public string CreatedAt { get; set; } = "";
}

public class InboxesDbContext : DbContext
{
    public DbSet<Message> Messages { get; set; } = null!;

    public InboxesDbContext(DbContextOptions<InboxesDbContext> options) : base(options) { }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        var entity = modelBuilder.Entity<Message>();
        entity.ToTable("messages");
        entity.HasKey(m => m.Id);
        entity.Property(m => m.Id).HasColumnName("id");
        entity.Property(m => m.Sender).HasColumnName("sender");
        entity.Property(m => m.Subject).HasColumnName("subject");
        entity.Property(m => m.Body).HasColumnName("body");
        entity.Property(m => m.Read).HasColumnName("read");
        entity.Property(m => m.CreatedAt).HasColumnName("created_at");
        entity.Property(m => m.Id).ValueGeneratedOnAdd();
    }
}