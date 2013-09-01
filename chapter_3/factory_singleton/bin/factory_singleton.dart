// use a factory constructor to implement the singleton pattern
class SearchEngine {
  static SearchEngine theOne;
  String name;

  factory SearchEngine(name) {
    if (theOne == null) {
      theOne = new SearchEngine._internal(name);
    }
    return theOne;
  }
// private, named constructor
  SearchEngine._internal(this.name);
// static method:
  static nameSearchEngine () => theOne.name;
}

main() {
  // substitute your favorite search-engine for se1:
  var se1 = new SearchEngine('Google');
  var se2 = new SearchEngine('Bing');
  print(se1.name);                        // 'Google'
  print(se2.name);                        // 'Google'
  print(SearchEngine.theOne.name);        // 'Google'
  print(SearchEngine.nameSearchEngine()); // 'Google'
  assert(identical(se1, se2));
}
