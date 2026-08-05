using PasswordGeneratorCli;
using Xunit;

namespace PasswordGeneratorCli.Tests;

public class PasswordGeneratorTests
{
    private const string Upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    private const string Lower = "abcdefghijklmnopqrstuvwxyz";
    private const string Digits = "0123456789";
    private const string Symbols = "!@#$%^&*()_+-=[]{}|;:,.<>?";

    [Fact]
    public void DefaultLength()
    {
        var pw = PasswordGenerator.Generate();
        Assert.Equal(16, pw.Length);
    }

    [Fact]
    public void CustomLength()
    {
        var pw = PasswordGenerator.Generate(24);
        Assert.Equal(24, pw.Length);
    }

    [Fact]
    public void MinLength()
    {
        var pw = PasswordGenerator.Generate(1, true, false, false, false);
        Assert.Equal(1, pw.Length);
    }

    [Fact]
    public void UppercasePresent()
    {
        var pw = PasswordGenerator.Generate(10, true, false, false, false);
        Assert.Matches("[A-Z]", pw);
    }

    [Fact]
    public void LowercasePresent()
    {
        var pw = PasswordGenerator.Generate(10, false, true, false, false);
        Assert.Matches("[a-z]", pw);
    }

    [Fact]
    public void DigitsPresent()
    {
        var pw = PasswordGenerator.Generate(10, false, false, true, false);
        Assert.Matches("[0-9]", pw);
    }

    [Fact]
    public void SymbolsPresent()
    {
        var pw = PasswordGenerator.Generate(10, false, false, false, true);
        Assert.Matches("[!@#$%^&*()_+\\-=\\[\\]{}|;:,.<>?]", pw);
    }

    [Fact]
    public void NoUppercase()
    {
        var pw = PasswordGenerator.Generate(16, false);
        Assert.DoesNotMatch("[A-Z]", pw);
    }

    [Fact]
    public void NoSymbols()
    {
        var pw = PasswordGenerator.Generate(16, true, true, true, false);
        Assert.DoesNotMatch("[!@#$%^&*()_+\\-=\\[\\]{}|;:,.<>?]", pw);
    }

    [Fact]
    public void NoLowercase()
    {
        var pw = PasswordGenerator.Generate(16, false, false);
        Assert.DoesNotMatch("[a-z]", pw);
    }

    [Fact]
    public void NoDigits()
    {
        var pw = PasswordGenerator.Generate(16, false, false, false);
        Assert.DoesNotMatch("[0-9]", pw);
    }

    [Fact]
    public void AllDisabledThrows()
    {
        Assert.Throws<ArgumentException>(() =>
            PasswordGenerator.Generate(10, false, false, false, false));
    }

    [Fact]
    public void LengthZeroThrows()
    {
        Assert.Throws<ArgumentException>(() =>
            PasswordGenerator.Generate(0));
    }

    [Fact]
    public void NegativeLengthThrows()
    {
        Assert.Throws<ArgumentException>(() =>
            PasswordGenerator.Generate(-5));
    }

    [Fact]
    public void LengthTooShortForCategories()
    {
        Assert.Throws<ArgumentException>(() =>
            PasswordGenerator.Generate(2, true, true, true, true));
    }

    [Fact]
    public void AtLeastOneFromEachEnabled()
    {
        var pw = PasswordGenerator.Generate(20, true, true, true, true);
        Assert.Matches("[A-Z]", pw);
        Assert.Matches("[a-z]", pw);
        Assert.Matches("[0-9]", pw);
        Assert.Matches("[!@#$%^&*()_+\\-=\\[\\]{}|;:,.<>?]", pw);
    }

    [Fact]
    public void OnlyUppercaseAndDigits()
    {
        var pw = PasswordGenerator.Generate(12, true, false, true, false);
        Assert.Matches("[A-Z]", pw);
        Assert.Matches("[0-9]", pw);
        Assert.DoesNotMatch("[a-z]", pw);
        Assert.DoesNotMatch("[!@#$%^&*()_+\\-=\\[\\]{}|;:,.<>?]", pw);
    }

    [Fact]
    public void ShuffledNotSequential()
    {
        var passwords = new HashSet<string>();
        for (int i = 0; i < 5; i++)
            passwords.Add(PasswordGenerator.Generate());
        Assert.True(passwords.Count > 1);
    }
}
