main() {
  var s1 = new Square(2);
  assert(s1.width == s1.length);
  assert(s1.height == s1.length);
  print('${s1.area()}'); // 4
  assert(s1 is Rectangle);
}

class Rectangle {
  num width, height;
  Rectangle(this.width, this.height);
  num area() => width * height;
}

class Square extends Rectangle {
  num length;
  Square(length): super(length, length) {
    this.length = length;
  }
  num area() => length * length;
}
