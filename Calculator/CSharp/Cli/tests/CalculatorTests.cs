using CalculatorCli;
using Xunit;

namespace CalculatorCli.Tests;

public class CalculatorTests
{
    [Fact]
    public void Add_ReturnsCorrectSum()
    {
        Assert.Equal(5, Calculator.Add(2, 3));
        Assert.Equal(0, Calculator.Add(-1, 1));
        Assert.Equal(0, Calculator.Add(0, 0));
    }

    [Fact]
    public void Subtract_ReturnsCorrectDifference()
    {
        Assert.Equal(2, Calculator.Subtract(5, 3));
        Assert.Equal(-5, Calculator.Subtract(0, 5));
        Assert.Equal(0, Calculator.Subtract(-1, -1));
    }

    [Fact]
    public void Multiply_ReturnsCorrectProduct()
    {
        Assert.Equal(6, Calculator.Multiply(2, 3));
        Assert.Equal(0, Calculator.Multiply(0, 5));
        Assert.Equal(-6, Calculator.Multiply(-2, 3));
    }

    [Fact]
    public void Divide_ReturnsCorrectQuotient()
    {
        var (result, error) = Calculator.Divide(6, 3);
        Assert.Equal(2, result);
        Assert.Null(error);
    }

    [Fact]
    public void DivideByZero_ReturnsError()
    {
        var (result, error) = Calculator.Divide(5, 0);
        Assert.Null(result);
        Assert.Equal("Error: Cannot divide by zero", error);
    }
}
