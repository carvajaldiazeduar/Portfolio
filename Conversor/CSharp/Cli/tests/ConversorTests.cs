using Xunit;

namespace ConversorCli.Tests;

public class ConversorTests
{
    [Fact]
    public void TestLengthConversion()
    {
        var result = Conversor.Convert(1, "m", "cm");
        Assert.Equal(100, result, 3);
    }

    [Fact]
    public void TestWeightConversion()
    {
        var result = Conversor.Convert(1, "kg", "g");
        Assert.Equal(1000, result, 3);
    }

    [Fact]
    public void TestTemperatureCtoF()
    {
        var result = Conversor.Convert(0, "C", "F");
        Assert.Equal(32, result, 3);
    }

    [Fact]
    public void TestTemperatureCtoK()
    {
        var result = Conversor.Convert(0, "C", "K");
        Assert.Equal(273.15, result, 3);
    }

    [Fact]
    public void TestTemperatureFtoC()
    {
        var result = Conversor.Convert(32, "F", "C");
        Assert.Equal(0, result, 3);
    }

    [Fact]
    public void TestTemperatureFtoK()
    {
        var result = Conversor.Convert(32, "F", "K");
        Assert.Equal(273.15, result, 3);
    }

    [Fact]
    public void TestTemperatureKtoC()
    {
        var result = Conversor.Convert(273.15, "K", "C");
        Assert.Equal(0, result, 3);
    }

    [Fact]
    public void TestTemperatureKtoF()
    {
        var result = Conversor.Convert(273.15, "K", "F");
        Assert.Equal(32, result, 3);
    }

    [Fact]
    public void TestInvalidUnit()
    {
        Assert.Throws<InvalidOperationException>(() => Conversor.Convert(1, "m", "kg"));
    }

    [Fact]
    public void TestIncompatibleCategories()
    {
        Assert.Throws<InvalidOperationException>(() => Conversor.Convert(1, "m", "kg"));
    }

    [Fact]
    public void TestListCategories()
    {
        var cats = Conversor.ListCategories();
        Assert.Contains("length", cats);
        Assert.Contains("weight", cats);
        Assert.Contains("temperature", cats);
    }

    [Fact]
    public void TestKmToMi()
    {
        var result = Conversor.Convert(1, "km", "mi");
        Assert.Equal(0.621371, result, 3);
    }

    [Fact]
    public void TestLbToOz()
    {
        var result = Conversor.Convert(1, "lb", "oz");
        Assert.Equal(16, result, 1);
    }

    [Fact]
    public void TestIdentity()
    {
        var result = Conversor.Convert(100, "cm", "cm");
        Assert.Equal(100, result, 3);
    }
}
