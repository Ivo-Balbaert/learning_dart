main() {
  var s1 = new Square(2);
  print('${s1.area()}');       // 4
  print('${s1.perimeter()}');  // 8
  var r1 = new Rectangle(2, 3);
  print('${r1.area()}');       // 6
  print('${r1.perimeter()}');  // 10
  assert(s1 is Form);
  assert(r1 is Form);
  // warning + exception in checked mode: Cannot instantiate abstract class Form
  // var f = new Form();
}

abstract class Form {
  num perimeter();
  num area();
}

//class Rectangle extends Form{
//  num width, height;
//  Rectangle(this.width, this.height);
//  num perimeter() => 2 * (height + width);
//  num area() => height * width;
//}
//
//class Square extends Form {
//  num length;
//  Square(this.length);
//  num perimeter() => 4 * length;
//  num area() => length * length;
//}

class Rectangle implements Form{
  num width, height;
  Rectangle(this.width, this.height);
  num perimeter() => 2 * (height + width);
  num area() => height * width;
}

class Square implements Form {
  num length;
  Square(this.length);
  num perimeter() => 4 * length;
  num area() => length * length;
}