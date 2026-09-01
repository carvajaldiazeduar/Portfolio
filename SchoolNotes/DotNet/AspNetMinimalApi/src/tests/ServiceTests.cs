using Microsoft.EntityFrameworkCore;
using Xunit;

namespace SchoolNotes.Tests;

public class ServiceTests
{
    static SchoolNotesDbContext NewDb()
    {
        var options = new DbContextOptionsBuilder()
            .UseInMemoryDatabase(System.Guid.NewGuid().ToString())
            .Options;
        return new SchoolNotesDbContext(options);
    }

    [Fact]
    public void Student_Create_List_Delete_Works()
    {
        using SchoolNotesDbContext db = NewDb();
        StudentService service = new StudentService(db);
        Student created = service.Create(new Student { FirstName = "Ana", LastName = "Lopez", Code = "A1" });
        Assert.True(created.Id > 0);
        Assert.Single(service.List(1, 10));

        (bool ok, string _) = service.Delete(created.Id);
        Assert.True(ok);
        Assert.Empty(service.List(1, 10));
    }

    [Fact]
    public void Student_Delete_Blocked_When_Enrollments_Exist()
    {
        using SchoolNotesDbContext db = NewDb();
        Student student = new StudentService(db).Create(new Student { FirstName = "Ana", LastName = "Lopez", Code = "A1" });
        new CourseService(db).Create(new Course { Name = "Math", TeacherId = 1 });
        Period period = new PeriodService(db).Create(new Period { Name = "2026" });
        new EnrollmentService(db).Create(new Enrollment { StudentId = student.Id, CourseId = 1, PeriodId = period.Id });

        (bool ok, string message) = new StudentService(db).Delete(student.Id);
        Assert.False(ok);
        Assert.Contains("dependent", message);
    }

    [Fact]
    public void Course_Delete_Blocked_When_Enrollments_Exist()
    {
        using SchoolNotesDbContext db = NewDb();
        new StudentService(db).Create(new Student { FirstName = "Ana", LastName = "Lopez", Code = "A1" });
        Course course = new CourseService(db).Create(new Course { Name = "Math", TeacherId = 1 });
        Period period = new PeriodService(db).Create(new Period { Name = "2026" });
        new EnrollmentService(db).Create(new Enrollment { StudentId = 1, CourseId = course.Id, PeriodId = period.Id });

        (bool ok, string _) = new CourseService(db).Delete(course.Id);
        Assert.False(ok);
    }

    [Fact]
    public void Teacher_Create_DuplicateCode_Rejected()
    {
        using SchoolNotesDbContext db = NewDb();
        TeacherService svc = new TeacherService(db);
        svc.Create(new Teacher { FirstName = "T1", LastName = "L1", Code = "TC1" });

        Dictionary<string, string> errors = svc.ValidateCreate(new Teacher { FirstName = "T2", LastName = "L2", Code = "TC1" });
        Assert.True(errors.ContainsKey("Code"));
    }

    [Fact]
    public void Student_Create_DuplicateCode_Rejected()
    {
        using SchoolNotesDbContext db = NewDb();
        StudentService svc = new StudentService(db);
        svc.Create(new Student { FirstName = "A", LastName = "B", Code = "SC1" });

        Dictionary<string, string> errors = svc.ValidateCreate(new Student { FirstName = "C", LastName = "D", Code = "SC1" });
        Assert.True(errors.ContainsKey("Code"));
    }

    [Fact]
    public void Student_Update_SameCode_Allowed()
    {
        using SchoolNotesDbContext db = NewDb();
        StudentService svc = new StudentService(db);
        Student existing = svc.Create(new Student { FirstName = "A", LastName = "B", Code = "SC1" });

        Dictionary<string, string> errors = svc.ValidateUpdate(existing.Id, new Student { FirstName = "A", LastName = "B", Code = "SC1" });
        Assert.False(errors.ContainsKey("Code"));
    }

    [Fact]
    public void Student_Update_AnotherCode_Rejected()
    {
        using SchoolNotesDbContext db = NewDb();
        StudentService svc = new StudentService(db);
        svc.Create(new Student { FirstName = "A", LastName = "B", Code = "SC1" });
        Student other = svc.Create(new Student { FirstName = "C", LastName = "D", Code = "SC2" });

        Dictionary<string, string> errors = svc.ValidateUpdate(other.Id, new Student { FirstName = "C", LastName = "D", Code = "SC1" });
        Assert.True(errors.ContainsKey("Code"));
    }

    [Fact]
    public void Enrollment_Create_Duplicate_Rejected()
    {
        using SchoolNotesDbContext db = NewDb();
        Student student = new StudentService(db).Create(new Student { FirstName = "A", LastName = "B", Code = "SC1" });
        new CourseService(db).Create(new Course { Name = "Math", TeacherId = 1 });
        Period period = new PeriodService(db).Create(new Period { Name = "2026" });
        EnrollmentService svc = new EnrollmentService(db);
        svc.Create(new Enrollment { StudentId = student.Id, CourseId = 1, PeriodId = period.Id });

        Dictionary<string, string> errors = svc.ValidateCreate(new Enrollment { StudentId = student.Id, CourseId = 1, PeriodId = period.Id });
        Assert.True(errors.ContainsKey("Enrollment"));
    }

    [Fact]
    public void Teacher_CRUD_Works()
    {
        using SchoolNotesDbContext db = NewDb();
        TeacherService svc = new TeacherService(db);
        Teacher created = svc.Create(new Teacher { FirstName = "John", LastName = "Doe", Code = "T001", Email = "john@test.com" });
        Assert.True(created.Id > 0);
        Assert.Equal("John", created.FirstName);

        Teacher fetched = svc.Get(created.Id);
        Assert.NotNull(fetched);
        Assert.Equal("John", fetched.FirstName);

        Teacher updated = svc.Update(created.Id, new Teacher { Id = created.Id, FirstName = "Jane", LastName = "Doe", Code = "T001", Email = "jane@test.com" });
        Assert.Equal("Jane", updated.FirstName);

        (bool ok, string _) = svc.Delete(created.Id);
        Assert.True(ok);
        Assert.Null(svc.Get(created.Id));
    }

    [Fact]
    public void Course_CRUD_Works()
    {
        using SchoolNotesDbContext db = NewDb();
        Teacher teacher = new TeacherService(db).Create(new Teacher { FirstName = "T", LastName = "L", Code = "TC1" });
        CourseService svc = new CourseService(db);
        Course created = svc.Create(new Course { Name = "Physics", TeacherId = teacher.Id });
        Assert.True(created.Id > 0);

        Course fetched = svc.Get(created.Id);
        Assert.NotNull(fetched);
        Assert.Equal("Physics", fetched.Name);

        Course updated = svc.Update(created.Id, new Course { Id = created.Id, Name = "Chemistry", TeacherId = teacher.Id });
        Assert.Equal("Chemistry", updated.Name);

        (bool ok, string _) = svc.Delete(created.Id);
        Assert.True(ok);
        Assert.Null(svc.Get(created.Id));
    }

    [Fact]
    public void Period_CRUD_Works()
    {
        using SchoolNotesDbContext db = NewDb();
        PeriodService svc = new PeriodService(db);
        Period created = svc.Create(new Period { Name = "2026-II", StartDate = new DateTime(2026, 8, 1), EndDate = new DateTime(2026, 12, 31) });
        Assert.True(created.Id > 0);

        Period fetched = svc.Get(created.Id);
        Assert.NotNull(fetched);
        Assert.Equal("2026-II", fetched.Name);

        Period updated = svc.Update(created.Id, new Period { Id = created.Id, Name = "2026-II-Updated", StartDate = new DateTime(2026, 8, 1), EndDate = new DateTime(2026, 12, 31) });
        Assert.Equal("2026-II-Updated", updated.Name);

        (bool ok, string _) = svc.Delete(created.Id);
        Assert.True(ok);
        Assert.Null(svc.Get(created.Id));
    }

    [Fact]
    public void Grade_CRUD_Works()
    {
        using SchoolNotesDbContext db = NewDb();
        Student student = new StudentService(db).Create(new Student { FirstName = "A", LastName = "B", Code = "S1" });
        Teacher teacher = new TeacherService(db).Create(new Teacher { FirstName = "T", LastName = "L", Code = "T1" });
        Course course = new CourseService(db).Create(new Course { Name = "Math", TeacherId = teacher.Id });
        Period period = new PeriodService(db).Create(new Period { Name = "2026" });
        Enrollment enrollment = new EnrollmentService(db).Create(new Enrollment { StudentId = student.Id, CourseId = course.Id, PeriodId = period.Id });

        GradeService svc = new GradeService(db);
        Grade created = svc.Create(new Grade { EnrollmentId = enrollment.Id, Label = "Exam 1", Score = 90, MaxScore = 100 });
        Assert.True(created.Id > 0);

        Grade fetched = svc.Get(created.Id);
        Assert.NotNull(fetched);
        Assert.Equal(90, fetched.Score);

        Grade updated = svc.Update(created.Id, new Grade { Id = created.Id, EnrollmentId = enrollment.Id, Label = "Exam 1 Updated", Score = 95, MaxScore = 100 });
        Assert.Equal(95, updated.Score);

        (bool ok, string _) = svc.Delete(created.Id);
        Assert.True(ok);
        Assert.Null(svc.Get(created.Id));
    }

    [Fact]
    public void Teacher_Delete_Blocked_When_Courses_Exist()
    {
        using SchoolNotesDbContext db = NewDb();
        Teacher teacher = new TeacherService(db).Create(new Teacher { FirstName = "T", LastName = "L", Code = "TC1" });
        new CourseService(db).Create(new Course { Name = "Math", TeacherId = teacher.Id });

        (bool ok, string message) = new TeacherService(db).Delete(teacher.Id);
        Assert.False(ok);
        Assert.Contains("dependent", message);
    }
}
