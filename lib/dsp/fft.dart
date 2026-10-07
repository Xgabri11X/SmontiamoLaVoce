import 'dart:math' as math;

class ComplexValue {
  double re;
  double im;
  ComplexValue(this.re, this.im);

  ComplexValue operator +(ComplexValue other) =>
      ComplexValue(re + other.re, im + other.im);
  ComplexValue operator -(ComplexValue other) =>
      ComplexValue(re - other.re, im - other.im);
  ComplexValue operator *(ComplexValue other) => ComplexValue(
        re * other.re - im * other.im,
        re * other.im + im * other.re,
      );
  double get magnitude => math.sqrt(re * re + im * im);
}

List<ComplexValue> fftReal(List<double> input) {
  var n = 1;
  while (n < input.length) n <<= 1;
  final a = List<ComplexValue>.generate(
    n,
    (i) => ComplexValue(i < input.length ? input[i] : 0.0, 0.0),
  );

  for (var i = 1, j = 0; i < n; i++) {
    var bit = n >> 1;
    for (; (j & bit) != 0; bit >>= 1) {
      j ^= bit;
    }
    j ^= bit;
    if (i < j) {
      final tmp = a[i];
      a[i] = a[j];
      a[j] = tmp;
    }
  }

  for (var len = 2; len <= n; len <<= 1) {
    final angle = -2 * math.pi / len;
    final wLen = ComplexValue(math.cos(angle), math.sin(angle));
    for (var i = 0; i < n; i += len) {
      var w = ComplexValue(1.0, 0.0);
      for (var j = 0; j < len ~/ 2; j++) {
        final u = a[i + j];
        final v = a[i + j + len ~/ 2] * w;
        a[i + j] = u + v;
        a[i + j + len ~/ 2] = u - v;
        w = w * wLen;
      }
    }
  }
  return a;
}
