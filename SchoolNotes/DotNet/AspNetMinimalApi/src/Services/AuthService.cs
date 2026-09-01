class AuthService
{
    private readonly SchoolNotesDbContext _db;

    public AuthService(SchoolNotesDbContext db)
    {
        _db = db;
    }

    public bool Register(string username, string password)
    {
        if (_db.Users.Any(u => u.Username == username))
            return false;

        string hash = BCrypt.Net.BCrypt.HashPassword(password);
        _db.Users.Add(new User { Username = username, PasswordHash = hash, Role = "admin" });
        _db.SaveChanges();

        return true;
    }

    public bool Verify(string username, string password, out User user)
    {
        user = _db.Users.FirstOrDefault(u => u.Username == username);
        if (user == null)
            return false;

        return BCrypt.Net.BCrypt.Verify(password, user.PasswordHash);
    }
}
