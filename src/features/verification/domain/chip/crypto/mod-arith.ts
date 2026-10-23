// BigInt modular arithmetic. Verification only: runs on public data, so no
// constant-time requirement.

export function mod(a: bigint, m: bigint): bigint {
  const r = a % m;
  return r >= 0n ? r : r + m;
}

export function modPow(base: bigint, exponent: bigint, m: bigint): bigint {
  let result = 1n;
  let b = mod(base, m);
  let e = exponent;
  while (e > 0n) {
    if (e & 1n) result = (result * b) % m;
    b = (b * b) % m;
    e >>= 1n;
  }
  return result;
}

// Extended Euclid; throws when no inverse exists.
export function modInv(a: bigint, m: bigint): bigint {
  let [oldR, r] = [mod(a, m), m];
  let [oldS, s] = [1n, 0n];
  while (r !== 0n) {
    const q = oldR / r;
    [oldR, r] = [r, oldR - q * r];
    [oldS, s] = [s, oldS - q * s];
  }
  if (oldR !== 1n) throw new RangeError("no modular inverse");
  return mod(oldS, m);
}

const SMALL_PRIMES = [2n, 3n, 5n, 7n, 11n, 13n, 17n, 19n, 23n, 29n, 31n, 37n, 41n, 43n, 47n, 53n];

// Miller-Rabin with the first 16 primes as bases.
export function isProbablePrime(n: bigint): boolean {
  if (n < 2n) return false;
  for (const p of SMALL_PRIMES) {
    if (n === p) return true;
    if (n % p === 0n) return false;
  }
  let d = n - 1n;
  let r = 0;
  while ((d & 1n) === 0n) {
    d >>= 1n;
    r++;
  }
  for (const a of SMALL_PRIMES) {
    let x = modPow(a, d, n);
    if (x === 1n || x === n - 1n) continue;
    let composite = true;
    for (let i = 1; i < r; i++) {
      x = (x * x) % n;
      if (x === n - 1n) {
        composite = false;
        break;
      }
    }
    if (composite) return false;
  }
  return true;
}

export function bitLength(n: bigint): number {
  return n === 0n ? 0 : n.toString(2).length;
}

export function isqrt(n: bigint): bigint {
  if (n < 2n) return n;
  let x = 1n << BigInt(Math.ceil(bitLength(n) / 2));
  for (;;) {
    const y = (x + n / x) >> 1n;
    if (y >= x) return x;
    x = y;
  }
}

// Square root modulo an odd prime (Tonelli-Shanks); undefined if `a` is a non-residue.
export function modSqrt(a: bigint, p: bigint): bigint | undefined {
  const n = mod(a, p);
  if (n === 0n) return 0n;
  if (modPow(n, (p - 1n) >> 1n, p) !== 1n) return undefined;
  if (p % 4n === 3n) return modPow(n, (p + 1n) >> 2n, p);
  let q = p - 1n;
  let s = 0;
  while ((q & 1n) === 0n) {
    q >>= 1n;
    s++;
  }
  let z = 2n;
  while (modPow(z, (p - 1n) >> 1n, p) !== p - 1n) z++;
  let m = s;
  let c = modPow(z, q, p);
  let t = modPow(n, q, p);
  let r = modPow(n, (q + 1n) >> 1n, p);
  while (t !== 1n) {
    let i = 0;
    let t2 = t;
    while (t2 !== 1n) {
      t2 = (t2 * t2) % p;
      i++;
    }
    const b = modPow(c, 1n << BigInt(m - i - 1), p);
    m = i;
    c = (b * b) % p;
    t = (t * c) % p;
    r = (r * b) % p;
  }
  return r;
}
