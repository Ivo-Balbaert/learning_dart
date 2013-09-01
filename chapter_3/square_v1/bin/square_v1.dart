import 'dart:math';

void main() {
  var s1 = new Square(2);
  print('${s1.perimeter}'); // 8
  print('${s1.area}');      // 4
  print('${s1.diagonal}');  // 2.8284271247461903
  var s2 = new Square(3);
  if (s2 > s1) print('square s2 is bigger than square s1');
  // square s2 is bigger than square s1
  var s3 = new Square(3);
  assert(!identical(s2,s3));
  // immutable squares:
  var s4 = const ImmutableSquare(4);
  var s5 = const ImmutableSquare(4);
  assert(identical(s4,s5));
}

class Square {
  num length;
  Square(this.length);

  num get perimeter => 4 * length;
  num get area => length * length;
  num get diagonal => length * SQRT2;

  bool operator >(Square other) =>
      length > other.length ? true : false;
}

class ImmutableSquare {
  final num length;
  static final ImmutableSquare one = const ImmutableSquare(1);
  const ImmutableSquare(this.length);
}