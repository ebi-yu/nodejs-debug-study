import { describe, expect, it } from "vitest";
import { primesInRange, sievePrimes } from "./sample-script.js";

describe("sievePrimes の動作", () => {
  it("上限が 0 のとき sievePrimes を実行すると 結果は [] になる", () => {
    // Arrange
    const n = 0;

    // Act
    const result = sievePrimes(n);

    // Assert
    expect(result).toEqual([]);
  });
  it("上限が 1 のとき sievePrimes を実行すると 結果は [] になる", () => {
    // Arrange
    const n = 1;

    // Act
    const result = sievePrimes(n);

    // Assert
    expect(result).toEqual([]);
  });

  it("上限が 2 のとき sievePrimes を実行すると [2] を返す", () => {
    // Arrange
    const n = 2;

    // Act
    const result = sievePrimes(n);

    // Assert
    expect(result).toEqual([2]);
  });

  it("上限が 10 のとき sievePrimes を実行すると [2,3,5,7] を返す", () => {
    // Arrange
    const n = 10;

    // Act
    const result = sievePrimes(n);

    // Assert
    expect(result).toEqual([2, 3, 5, 7]);
  });

  it("上限が 100 のとき sievePrimes を実行すると [2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97] を返す", () => {
    // Arrange
    const n = 100;

    // Act
    const result = sievePrimes(n);

    // Assert
    expect(result).toEqual([
      2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67,
      71, 73, 79, 83, 89, 97,
    ]);
  });
});

describe("primesInRange の動作", () => {
  it("範囲が [14,16] のとき primesInRange を実行すると [] を返す", () => {
    // Arrange
    const low = 14;
    const high = 16;

    // Act
    const result = primesInRange(low, high);

    // Assert
    expect(result).toEqual([]);
  });

  it("範囲が [17,17] のとき primesInRange を実行すると [17] を返す", () => {
    // Arrange
    const low = 17;
    const high = 17;

    // Act
    const result = primesInRange(low, high);

    // Assert
    expect(result).toEqual([17]);
  });

  it("範囲が [10,30] のとき primesInRange を実行すると [11,13,17,19,23,29] を返す", () => {
    // Arrange
    const low = 10;
    const high = 30;

    // Act
    const result = primesInRange(low, high);

    // Assert
    expect(result).toEqual([11, 13, 17, 19, 23, 29]);
  });
});
