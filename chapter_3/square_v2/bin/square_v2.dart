main() {
  var s1 = new Square(2);
  print(s1.width);  // 2
  print(s1.height); // 2
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
