using System.Collections.Generic;
using Xunit;

namespace SchoolNotes.Tests;

public class ValidatorsTests
{
    [Fact]
    public void Student_Rejects_LongFirstName()
    {
        Student entity = new Student { FirstName = new string('a', 101), LastName = "x", Code = "c" };
        Dictionary<string, string> errors = Validators.Student(entity);
        Assert.Contains("FirstName", errors.Keys);
    }

    [Fact]
    public void Student_Rejects_LongLastName()
    {
        Student entity = new Student { FirstName = "x", LastName = new string('a', 101), Code = "c" };
        Dictionary<string, string> errors = Validators.Student(entity);
        Assert.Contains("LastName", errors.Keys);
    }

    [Fact]
    public void Student_Rejects_LongCode()
    {
        Student entity = new Student { FirstName = "x", LastName = "y", Code = new string('c', 21) };
        Dictionary<string, string> errors = Validators.Student(entity);
        Assert.Contains("Code", errors.Keys);
    }

    [Fact]
    public void Student_Rejects_LongEmail()
    {
        Student entity = new Student { FirstName = "x", LastName = "y", Code = "c", Email = new string('a', 201) };
        Dictionary<string, string> errors = Validators.Student(entity);
        Assert.Contains("Email", errors.Keys);
    }

    [Fact]
    public void Student_Requires_FirstName()
    {
        Student entity = new Student { FirstName = "", LastName = "y", Code = "c" };
        Dictionary<string, string> errors = Validators.Student(entity);
        Assert.Contains("FirstName", errors.Keys);
    }

    [Fact]
    public void Student_Requires_LastName()
    {
        Student entity = new Student { FirstName = "x", LastName = "", Code = "c" };
        Dictionary<string, string> errors = Validators.Student(entity);
        Assert.Contains("LastName", errors.Keys);
    }

    [Fact]
    public void Student_Requires_Code()
    {
        Student entity = new Student { FirstName = "x", LastName = "y", Code = "" };
        Dictionary<string, string> errors = Validators.Student(entity);
        Assert.Contains("Code", errors.Keys);
    }

    [Fact]
    public void Student_Accepts_Valid()
    {
        Student entity = new Student { FirstName = "Ana", LastName = "Lopez", Code = "A1" };
        Assert.Empty(Validators.Student(entity));
    }

    [Fact]
    public void Teacher_Rejects_LongFirstName()
    {
        Teacher entity = new Teacher { FirstName = new string('a', 101), LastName = "x", Code = "c" };
        Dictionary<string, string> errors = Validators.Teacher(entity);
        Assert.Contains("FirstName", errors.Keys);
    }

    [Fact]
    public void Teacher_Rejects_LongLastName()
    {
        Teacher entity = new Teacher { FirstName = "x", LastName = new string('a', 101), Code = "c" };
        Dictionary<string, string> errors = Validators.Teacher(entity);
        Assert.Contains("LastName", errors.Keys);
    }

    [Fact]
    public void Teacher_Rejects_LongCode()
    {
        Teacher entity = new Teacher { FirstName = "x", LastName = "y", Code = new string('c', 21) };
        Dictionary<string, string> errors = Validators.Teacher(entity);
        Assert.Contains("Code", errors.Keys);
    }

    [Fact]
    public void Teacher_Rejects_LongEmail()
    {
        Teacher entity = new Teacher { FirstName = "x", LastName = "y", Code = "c", Email = new string('a', 201) };
        Dictionary<string, string> errors = Validators.Teacher(entity);
        Assert.Contains("Email", errors.Keys);
    }

    [Fact]
    public void Teacher_Requires_Fields()
    {
        Teacher entity = new Teacher { FirstName = "", LastName = "", Code = "" };
        Dictionary<string, string> errors = Validators.Teacher(entity);
        Assert.Contains("FirstName", errors.Keys);
        Assert.Contains("LastName", errors.Keys);
        Assert.Contains("Code", errors.Keys);
    }

    [Fact]
    public void Course_Rejects_LongName()
    {
        Course entity = new Course { Name = new string('a', 151), TeacherId = 1 };
        Dictionary<string, string> errors = Validators.Course(entity);
        Assert.Contains("Name", errors.Keys);
    }

    [Fact]
    public void Course_Requires_TeacherId()
    {
        Course entity = new Course { Name = "Math", TeacherId = 0 };
        Dictionary<string, string> errors = Validators.Course(entity);
        Assert.Contains("TeacherId", errors.Keys);
    }

    [Fact]
    public void Course_Accepts_Valid()
    {
        Course entity = new Course { Name = "Math", TeacherId = 1 };
        Assert.Empty(Validators.Course(entity));
    }

    [Fact]
    public void Period_Rejects_LongName()
    {
        Period entity = new Period { Name = new string('a', 51) };
        Dictionary<string, string> errors = Validators.Period(entity);
        Assert.Contains("Name", errors.Keys);
    }

    [Fact]
    public void Period_Requires_Name()
    {
        Period entity = new Period { Name = "" };
        Dictionary<string, string> errors = Validators.Period(entity);
        Assert.Contains("Name", errors.Keys);
    }

    [Fact]
    public void Period_Accepts_Valid()
    {
        Period entity = new Period { Name = "2026-I" };
        Assert.Empty(Validators.Period(entity));
    }

    [Fact]
    public void Enrollment_Requires_StudentId()
    {
        Enrollment entity = new Enrollment { StudentId = 0, CourseId = 1, PeriodId = 1 };
        Dictionary<string, string> errors = Validators.Enrollment(entity);
        Assert.Contains("StudentId", errors.Keys);
    }

    [Fact]
    public void Enrollment_Requires_CourseId()
    {
        Enrollment entity = new Enrollment { StudentId = 1, CourseId = 0, PeriodId = 1 };
        Dictionary<string, string> errors = Validators.Enrollment(entity);
        Assert.Contains("CourseId", errors.Keys);
    }

    [Fact]
    public void Enrollment_Requires_PeriodId()
    {
        Enrollment entity = new Enrollment { StudentId = 1, CourseId = 1, PeriodId = 0 };
        Dictionary<string, string> errors = Validators.Enrollment(entity);
        Assert.Contains("PeriodId", errors.Keys);
    }

    [Fact]
    public void Enrollment_Accepts_Valid()
    {
        Enrollment entity = new Enrollment { StudentId = 1, CourseId = 1, PeriodId = 1 };
        Assert.Empty(Validators.Enrollment(entity));
    }

    [Fact]
    public void Grade_Rejects_Score_Above_Max()
    {
        Grade entity = new Grade { Label = "Quiz", Score = 120, MaxScore = 100 };
        Dictionary<string, string> errors = Validators.Grade(entity);
        Assert.Contains("Score", errors.Keys);
    }

    [Fact]
    public void Grade_Rejects_Negative_Score()
    {
        Grade entity = new Grade { Label = "Quiz", Score = -1, MaxScore = 100 };
        Dictionary<string, string> errors = Validators.Grade(entity);
        Assert.Contains("Score", errors.Keys);
    }

    [Fact]
    public void Grade_Rejects_Zero_MaxScore()
    {
        Grade entity = new Grade { Label = "Quiz", Score = 50, MaxScore = 0 };
        Dictionary<string, string> errors = Validators.Grade(entity);
        Assert.Contains("MaxScore", errors.Keys);
    }

    [Fact]
    public void Grade_Rejects_Negative_MaxScore()
    {
        Grade entity = new Grade { Label = "Quiz", Score = 50, MaxScore = -1 };
        Dictionary<string, string> errors = Validators.Grade(entity);
        Assert.Contains("MaxScore", errors.Keys);
    }

    [Fact]
    public void Grade_Rejects_LongLabel()
    {
        Grade entity = new Grade { Label = new string('a', 101), Score = 50, MaxScore = 100 };
        Dictionary<string, string> errors = Validators.Grade(entity);
        Assert.Contains("Label", errors.Keys);
    }

    [Fact]
    public void Grade_Rejects_LongObservation()
    {
        Grade entity = new Grade { Label = "Quiz", Score = 50, MaxScore = 100, Observation = new string('a', 501) };
        Dictionary<string, string> errors = Validators.Grade(entity);
        Assert.Contains("Observation", errors.Keys);
    }

    [Fact]
    public void Grade_Requires_Label()
    {
        Grade entity = new Grade { Label = "", Score = 50, MaxScore = 100 };
        Dictionary<string, string> errors = Validators.Grade(entity);
        Assert.Contains("Label", errors.Keys);
    }

    [Fact]
    public void Grade_Accepts_Valid()
    {
        Grade entity = new Grade { Label = "Quiz", Score = 85, MaxScore = 100 };
        Assert.Empty(Validators.Grade(entity));
    }
}
