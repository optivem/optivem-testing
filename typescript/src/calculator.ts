export class Calculator {
  add(a: number, b: number): number {
    return a + b;
  }

  subtract(a: number, b: number): number {
    return a - b;
  }

  multiply(a: number, b: number): number {
    return a * b;
  }

  divide(a: number, b: number): number {
    if (b === 0) {
      throw new Error("Division by zero is not allowed");
    }
    return a / b;
  }

  modulo(a: number, b: number): number {
    if (b === 0) {
      throw new Error("Modulo by zero is not allowed");
    }
    return a % b;
  }

  power(base: number, exponent: number): number {
    return Math.pow(base, exponent);
  }
}
