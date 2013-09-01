void main() {
// constructing Maps:
  Map webLinks =   {  'Dart': 'http://www.dartlang.org/',
                     'HTML5': 'http://www.html5rocks.com/' };
  Map webLinks2 = new Map();
  webLinks2['Dart'] = 'http://www.dartlang.org/';
  webLinks2['HTML5'] = 'http://www.html5rocks.com/';
  assert(webLinks.length==2 && webLinks2.length==2);
// empty Map:
  var map = {};
  var map2 = new Map();
  assert(map2.length==0 && map2.length==0);
// fetching a value:
  var link = webLinks2['Dart'];
  print('The link is: $link'); // http://www.dartlang.org/
  var link2 = webLinks2['C'];
  print('The link is: $link2'); // null
  if (webLinks2.containsKey('C'))
    print("The map webLinks2 contains key 'C");
  else
    print("The map webLinks2 does not contain key 'C'");
  // prints: The map webLinks2 does not contain key 'C'
  // setting or changing a value:
  print('$webLinks2');
  webLinks2['Dart'] = 'http://www.learningdart.org/';
  webLinks2['ASP.NET'] = 'http://www.asp.net/';
  print('$webLinks2');
  // {Dart: http://www.learningdart.org/, HTML5: http://www.html5rocks.com/, ASP.NET: http://www.asp.net/}
  assert(webLinks2.length==3);
  // getting the keys:
  var keys = webLinks2.keys.toList();
  print('$keys'); // [Dart, HTML5, ASP.NET]
  // getting the values:
  var values = webLinks2.values.toList();
  print('$values');
  // [http://www.learningdart.org/, http://www.html5rocks.com/, http://www.asp.net/]
  // putIfAbsent:
  webLinks2.putIfAbsent('F#', () => 'www.fsharp.net');
  assert(webLinks2['F#']=="www.fsharp.net");
// const maps:
  var cities =  const {  '1': 'London', '2': 'Tokyo', '3': 'Washington'};

}
