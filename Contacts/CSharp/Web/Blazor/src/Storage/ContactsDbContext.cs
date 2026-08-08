using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore;

public class Contact
{
    public int Id { get; set; }

    [Required(ErrorMessage = "Name is required")]
    [StringLength(100, MinimumLength = 2, ErrorMessage = "Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)")]
    [RegularExpression(@"^[A-Za-zÀ-ÿ' .-]+$", ErrorMessage = "Name must be 2-100 characters (letters, spaces, apostrophes, hyphens, dots)")]
    public string Name { get; set; } = "";

    [Required(ErrorMessage = "Phone is required")]
    [RegularExpression(@"^[0-9 +().-]{7,20}$", ErrorMessage = "Phone must be 7-20 characters (digits, spaces, +, parentheses, dashes)")]
    public string Phone { get; set; } = "";

    [Required(ErrorMessage = "Email is required")]
    [RegularExpression(@"^[^\s@]+@[^\s@]+\.[^\s@]{2,}$", ErrorMessage = "Invalid email format")]
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