using System.Collections.Generic;

static class Validators
{
    public static Dictionary<string, string> Student(Student e)
    {
        Dictionary<string, string> errors = new Dictionary<string, string>();
        Require(errors, "FirstName", e.FirstName, 100);
        Require(errors, "LastName", e.LastName, 100);
        Require(errors, "Code", e.Code, 20);
        MaxLength(errors, "Email", e.Email, 200);
        return errors;
    }

    public static Dictionary<string, string> Teacher(Teacher e)
    {
        Dictionary<string, string> errors = new Dictionary<string, string>();
        Require(errors, "FirstName", e.FirstName, 100);
        Require(errors, "LastName", e.LastName, 100);
        Require(errors, "Code", e.Code, 20);
        MaxLength(errors, "Email", e.Email, 200);
        return errors;
    }

    public static Dictionary<string, string> Course(Course e)
    {
        Dictionary<string, string> errors = new Dictionary<string, string>();
        Require(errors, "Name", e.Name, 150);
        RequireId(errors, "TeacherId", e.TeacherId);
        return errors;
    }

    public static Dictionary<string, string> Period(Period e)
    {
        Dictionary<string, string> errors = new Dictionary<string, string>();
        Require(errors, "Name", e.Name, 50);
        return errors;
    }

    public static Dictionary<string, string> Enrollment(Enrollment e)
    {
        Dictionary<string, string> errors = new Dictionary<string, string>();
        RequireId(errors, "StudentId", e.StudentId);
        RequireId(errors, "CourseId", e.CourseId);
        RequireId(errors, "PeriodId", e.PeriodId);
        return errors;
    }

    public static Dictionary<string, string> Grade(Grade e)
    {
        Dictionary<string, string> errors = new Dictionary<string, string>();
        Require(errors, "Label", e.Label, 100);
        MaxLength(errors, "Observation", e.Observation, 500);
        if (e.MaxScore <= 0)
            errors["MaxScore"] = "MaxScore must be greater than zero.";

        if (e.Score < 0 || e.Score > e.MaxScore)
            errors["Score"] = $"Score must be between 0 and {e.MaxScore}.";

        return errors;
    }

    static void Require(Dictionary<string, string> errors, string field, string value, int max)
    {
        if (string.IsNullOrWhiteSpace(value))
            errors[field] = $"{field} is required.";
        else if (value.Length > max)
            errors[field] = $"{field} must be at most {max} characters.";
    }

    static void MaxLength(Dictionary<string, string> errors, string field, string value, int max)
    {
        if (!string.IsNullOrWhiteSpace(value) && value.Length > max)
            errors[field] = $"{field} must be at most {max} characters.";
    }

    static void RequireId(Dictionary<string, string> errors, string field, int value)
    {
        if (value <= 0)
            errors[field] = $"{field} is required.";
    }
}
