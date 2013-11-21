void main() {
  String country = "Egypt";
  String chineseForWorld = '世界';
  print(chineseForWorld);
  String q = "What's up?";
  String s1 = 'abc'
              "def";
  print(s1); // abcdef
  String multiLine = '''
    <h1> Beautiful page </h1>
    <div class="start"> This is a story about the landing 
       on the moon </div>
    <hr>
  ''';
  print(multiLine);
  String rawStr = r"Why don't you \t learn Dart!"; // Why don't you \t learn Dart!
  print(rawStr);
  var emptyStr = ''; // empty string

  int n = 42;
  double pi = 3.14;
  int hex = 0xDEADBEEF;
  int hugePrimeNumber = 4776913109852041418248056622882488319;
  double d1 = 12345e-4; // 1.2345
  var i1 = d1.round();  // 1.0

  bool selected = false;

  // conversions:
  String lucky = 7.toString();
  int seven = int.parse('7');
  double pi2 = double.parse('3.1415');
  String pi2Str = pi2.toStringAsFixed(3);  //  3.142
  print(pi2Str);
  var doubleSeven = seven.toDouble();
  var intPi2 = pi2.toInt();
  print(intPi2); // 3

  // operators:
  var i = 100;
  var j = 1000;
  var b1 = (i == j);  // () are not necessary
  var b2 = (i!= j);
  print(b1); // false
  print(b2); // true

  // equality of strings
  var s = "strings are immutable";
  var t = "strings are immutable";
  print(s == t); // true, they contain the same characters
  print(identical(s, t)); // true, they are the same object in memory

  var b3 = (7 is num); // () are not necessary
  print(b3); // true
  //var b4 = (7 is! double);
  var b4 = (7 is int);
  print(b4); // true, it's an int
  assert(b4);

//var b5 = (n as String) is String;
//print(b5); // true

}
