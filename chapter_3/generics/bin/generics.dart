void main() {
// if you want to see line 25 (langs2.add(42);) in runtime mode, 
// uncomment and uncheck Run in checked mode  
// lists:
  var date = new DateTime.now();
  // untyped List:
  var lst1 = [7, "lucky number", 56.2, date];
  print('$lst1'); // [7, lucky number, 56.2, 2013-02-22 10:08:20.074]
  print('${lst1 is List<dynamic>}'); // true
  var lst2 = new List();
  lst2.add(7);
  lst2.add("lucky number");
  lst2.add(56.2);
  lst2.add(date);
  print('$lst2'); // [7, lucky number, 56.2, 2013-02-22 10:08:20.074]
  print('${lst2 is List}');  // true
  // assert(lst2 is List<String>); // TypeErrorImplementation
  // typed list:
  var langs = <String>["Python","Ruby", "Dart"];
  var langs2 = new List<String>();
  var lstOfString = new List<List<String>>();
  langs2.add("Python");
  langs2.add("Ruby");
  langs2.add("Dart");
  // langs2.add(42);
  print('${langs2 is List}'); // true
  print('${langs2 is List<String>}'); // true
  print('${langs2 is List<double>}'); // false
  for (var s in langs2) {
    if (s is String) print('$s is a String');
    else             print ('$s is not a String!');
  }
  // output:
//  Python is a String
//  Ruby is a String
//  Dart is a String
//  42 is not a String!
// maps:
  var map = new Map<int, String>();
  map[1] = 'Dart';
  map[2] = 'JavaScript';
  map[3] = "Java";
  map[4] = "C#";
  print("$map"); // {1: Dart, 2: JavaScript, 3: Java, 4: C#}
  // map['five'] = 'Perl'; // String is not assignable to int
// reified generics:
  print('Generics');
  print(new List<String>() is List<Object>);   // true every string is an object
  print(new List<Object>() is List<String>);   // false not all objects are strings
  print(new List<String>() is List<int>); // false
  print(new List<String>() is List); // true
  print(new List() is List<String>); // true


}
