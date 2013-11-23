import 'dart:collection';
import 'dart:math' as Math;

void main() {
  var digits = new Iterable.generate(10, (i) => i);
  
//for (var no in digits) {
//  print(no);
//} // prints 0 1 2 3 4 5 6 7 8 9 on successive lines
  
  var digList = digits.toList();
  
  // functional methods:
  // forEach:
  // prints 0 1 2 3 4 5 6 7 8 9 on successive lines
  digList.forEach((i) => print('$i'));
  
  // forEach for Maps:
  Map webLinks =   {  'Dart': 'http://www.dartlang.org/',
                      'HTML5': 'http://www.html5rocks.com/' };
  webLinks.forEach((k,v) => print('$k')); // prints: Dart   HTML5
  
  // first - last:
  print('${digList.first}'); // 0
  print('${digList.last}');  // 9
  
  // skip and skipWhile:
  var skipL1 = digList.skip(4).toList();
  print('$skipL1'); // [4, 5, 6, 7, 8, 9]
  var skipL2 = digList.skipWhile((i) => i <= 6).toList();
  print('$skipL2'); // [7, 8, 9]
  
  // take and takeWhile:
  var takeL1 = digList.take(4).toList();
  print('$takeL1'); // [0, 1, 2, 3]
  var takeL2 = digList.takeWhile((i) => i <= 6).toList();
  print('$takeL2'); // [0, 1, 2, 3, 4, 5, 6]
  
  // any:
  var test = digList.any((i) => i > 10);
  print('$test');  // false
  var test2 = digList.every((i) => i < 10);
  print('$test2');  // true
  
  // filtering:
  var even = (i) => i.isEven;
  var evens = digList.where(even).toList();
  print('$evens');  // [0, 2, 4, 6, 8]
  evens = digList.where((i) => i.isEven).toList();
  // evens = digList.where( (i) => i.isEven );
  print('$evens');  // [0, 2, 4, 6, 8]
  
  // mapping:
  var triples = digList.map((i) => 3 * i).toList().toList();
  print('$triples'); // [0, 3, 6, 9, 12, 15, 18, 21, 24, 27]
  
  // calculate sum with for-loop:
  var sum = 0;
  for (var i in digList) {
    sum += i;
  }
  print('$sum'); // 45
  
  // calculate sum with reduce:
  var sum2 = digList.reduce((prev, i) => prev + i);
  print('$sum2'); // 45
  
  // minimum and maximum of a List:
  var min = digList.reduce(Math.min);
  print('minimum: $min'); // 0
  var max = digList.reduce(Math.max);
  print('maximum: $max'); // 9
  
  // sorting a List:
  var lst = [17, 3, -7, 42, 1000, 90];
  lst.sort();
  print('$lst'); [-7, 3, 17, 42, 90, 1000];
  
  // minimum and maximum of a List
  var lstS = ['heg', 'wyf', 'abc'];
  var minS = lstS.reduce((s1,s2) => s1.compareTo(s2) < 0 ? s1 : s2);
  print('Minimum String: $minS'); // abc
  
  // sorting a List of Persons:
  var p1 = new Person('Peeters Kris');
  var p2 = new Person('Obama Barak');
  var p3 = new Person('Poetin Vladimir');
  var p4 = new Person('Lincoln Abraham');
  var pList = [p1, p2, p3, p4];
  // pList.sort();
  // type 'Person' is not a subtype of type 'Comparable' of 'a'.
  // (1) Person implements interface Comparable:
  var minP = pList.reduce((s1,s2) => s1.compareTo(s2) < 0 ? s1 : s2);
  print('Minimum Person: ${minP.name}'); // Lincoln Abraham
  var maxP = pList.reduce((s1,s2) => s1.compareTo(s2) < 0 ? s2 : s1);
  print('Maximum Person: ${maxP.name}'); // Poetin Vladimir
  pList.sort();
  pList.forEach((p) => print('${p.name}'));
  
//prints on successive lines:
//Lincoln Abraham   Obama Barak  Peeters Kris   Poetin Vladimir
//(2) with the static method Comparable.compare:
//var comp2 = (Person p1, Person p2) => Comparable.compare(p1.name, p2.name);
//pList.sort(comp2);
//pList.forEach((p) => print('${p.name}'));
//prints on successive lines:
//Lincoln Abraham   Obama Barak  Peeters Kris   Poetin Vladimir

  // Queue:
  var langsQ = new Queue();
  langsQ.addFirst('Dart');
  langsQ.addFirst('JavaScript');
  print('${langsQ.elementAt(1)}'); // Dart
  var lng = langsQ.removeFirst();
  assert(lng=='JavaScript');
  langsQ.addLast('C#');
  langsQ.removeLast();
  print('$langsQ'); // {Dart}
  
  // Set:
  var langsS = new Set();
  langsS.add('Java');
  langsS.add('Dart');
  langsS.add('Java');
  langsS.length == 2;
  print('$langsS'); // {Dart, Java}
}

class Person implements Comparable{
  String name;
  Person(this.name);
  // many other properties and methods
  compareTo(Person p) => name.compareTo(p.name);
}
