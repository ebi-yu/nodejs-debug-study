function sievePrimes(limit) {
  const isPrime = new Array(limit + 1).fill(true);
  isPrime[0] = isPrime[1] = false;

  for (let i = 2; i * i <= limit; i++) {
    if (isPrime[i]) {
      // ここにブレイクポイントを設定 - 内側ループ
      for (let j = i * i; j <= limit; j += i) {
        isPrime[j] = false;
      }
    }
  }

  return isPrime
    .map((val, idx) => (val ? idx : null))
    .filter((n) => n !== null);
}

function primesInRange(low, high) {
  // ここにブレイクポイントを設定 - 関数開始
  const primes = sievePrimes(high);
  return primes.filter((p) => p >= low);
}

// ここにブレイクポイントを設定 - メイン実行
console.log(primesInRange(10, 50));

module.exports = { sievePrimes, primesInRange };
