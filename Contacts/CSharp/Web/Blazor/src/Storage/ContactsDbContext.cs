using Microsoft.EntityFrameworkCore;

public class Contact
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public string Phone { get; set; } = "";
    public string Email { get; set; } = "";
}

public class ContactsDbContext : DbContext
{
    public DbSet<Contact> Contacts { get; set; } = null!;

    public ContactsDbContext(DbContextOptions<ContactsDbContext> options) : base(options) { }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        var entity = modelBuilder.Entity<Contact>();
        entity.ToTable("contacts");
        entity.HasKey(c => c.Id);
        entity.Property(c => c.Id).HasColumnName("id");
        entity.Property(c => c.Name).HasColumnName("name").IsRequired();
        entity.Property(c => c.Phone).HasColumnName("phone");
        entity.Property(c => c.Email).HasColumnName("email");
        entity.Property(c => c.Id).ValueGeneratedOnAdd();
    }
}