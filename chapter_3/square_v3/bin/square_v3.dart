main() {
  var s1 = new Square(2);
  print('${s1.area()}');       // 4
  print('${s1.perimeter()}');  // 8
  var r1 = new Rectangle(2, 3);
  print('${r1.area()}');       // 6
  print('${r1.perimeter()}');  // 10
  assert(s1 is Shape);
  assert(r1 is Shape);
  // warning + exception in checked mode: Cannot instantiate abstract class Shape
  // var f = new Shape();
}

abstract class Shape {
  num perimeter();
  num area();
}

//class Rectangle extends Shape{
//  num width, height;
//  Rectangle(this.width, this.height);
//  num perimeter() => 2 * (height + width);
//  num area() => height * width;
//}
//
//class Square extends Shape {
//  num length;
//  Square(this.length);
//  num perimeter() => 4 * length;
//  num area() => length * length;
//}

class Rectangle implements Shape{
  num width, height;
  Rectangle(this.width, this.height);
  num perimeter() => 2 * (height + width);
  num area() => height * width;
}

class Square implements Shape {
  num length;
  Square(this.length);
  num perimeter() => 4 * length;
  num area() => length * length;
}