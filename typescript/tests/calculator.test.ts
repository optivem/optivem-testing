import { Calculator } from "../src/calculator.js";

describe("Calculator", () => {
  let calculator: Calculator;

  beforeEach(() => {
    calculator = new Calculator();
  });

  describe("add", () => {
    it("should return the sum of two positive numbers", () => {
      expect(calculator.add(2, 3)).toBe(5);
    });

    it("should return the sum when one number is negative", () => {
      expect(calculator.add(-1, 5)).toBe(4);
    });

    it("should return zero when adding a number and its negative", () => {
      expect(calculator.add(7, -7)).toBe(0);
    });

    it("should handle decimal numbers", () => {
      expect(calculator.add(0.1, 0.2)).toBeCloseTo(0.3);
    });
  });

  describe("subtract", () => {
    it("should return the difference of two numbers", () => {
      expect(calculator.subtract(10, 4)).toBe(6);
    });

    it("should return a negative result when subtracting a larger from a smaller", () => {
      expect(calculator.subtract(3, 8)).toBe(-5);
    });

    it("should return zero when subtracting equal numbers", () => {
      expect(calculator.subtract(5, 5)).toBe(0);
    });
  });

  describe("multiply", () => {
    it("should return the product of two positive numbers", () => {
      expect(calculator.multiply(3, 4)).toBe(12);
    });

    it("should return a negative product when one factor is negative", () => {
      expect(calculator.multiply(-2, 5)).toBe(-10);
    });

    it("should return a positive product when both factors are negative", () => {
      expect(calculator.multiply(-3, -4)).toBe(12);
    });

    it("should return zero when multiplying by zero", () => {
      expect(calculator.multiply(100, 0)).toBe(0);
    });
  });

  describe("divide", () => {
    it("should return the quotient of two numbers", () => {
      expect(calculator.divide(10, 2)).toBe(5);
    });

    it("should return a decimal result for non-even division", () => {
      expect(calculator.divide(7, 2)).toBe(3.5);
    });

    it("should return a negative result when dividing a positive by a negative", () => {
      expect(calculator.divide(9, -3)).toBe(-3);
    });

    it("should throw an error when dividing by zero", () => {
      expect(() => calculator.divide(5, 0)).toThrow("Division by zero is not allowed");
    });
  });

  describe("modulo", () => {
    it("should return the remainder of division", () => {
      expect(calculator.modulo(10, 3)).toBe(1);
    });

    it("should return zero when there is no remainder", () => {
      expect(calculator.modulo(12, 4)).toBe(0);
    });

    it("should throw an error when modulo by zero", () => {
      expect(() => calculator.modulo(5, 0)).toThrow("Modulo by zero is not allowed");
    });
  });

  describe("power", () => {
    it("should return the correct power of a number", () => {
      expect(calculator.power(2, 10)).toBe(1024);
    });

    it("should return 1 when the exponent is zero", () => {
      expect(calculator.power(5, 0)).toBe(1);
    });

    it("should handle negative exponents", () => {
      expect(calculator.power(2, -1)).toBe(0.5);
    });
  });
});
