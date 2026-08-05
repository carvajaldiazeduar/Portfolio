const { add, subtract, multiply, divide } = require("../calculator");

describe("Calculator", () => {
  test("add returns correct sum", () => {
    expect(add(2, 3)).toBe(5);
    expect(add(-1, 1)).toBe(0);
    expect(add(0, 0)).toBe(0);
  });

  test("subtract returns correct difference", () => {
    expect(subtract(5, 3)).toBe(2);
    expect(subtract(0, 5)).toBe(-5);
    expect(subtract(-1, -1)).toBe(0);
  });

  test("multiply returns correct product", () => {
    expect(multiply(2, 3)).toBe(6);
    expect(multiply(0, 5)).toBe(0);
    expect(multiply(-2, 3)).toBe(-6);
  });

  test("divide returns correct quotient", () => {
    expect(divide(6, 3)).toBe(2);
    expect(divide(5, 2)).toBe(2.5);
    expect(divide(0, 5)).toBe(0);
  });

  test("divide by zero returns error", () => {
    expect(divide(5, 0)).toBe("Error: Cannot divide by zero");
  });
});
