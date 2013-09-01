main() {
  var p1 = new Project();
  p1.name = 'Breeding';
  p1.description = 'Managing the breeding of animals';
  print('$p1');
  // prints: Project name: BREEDING - Managing the breeding of animals
  var p2 = new Project();
  p2.name = 'Project Breeding of all kinds of animals';
  print("We don't get here anymore because of the exception!");
}

class Project {
  String _name; // private variable
  String description;

  String get name => _name.toUpperCase();
  set name(String prName) {
    if (prName.length > 20)
      throw 'Only 20 characters or less in project name';
    _name = prName;
  }

  toString() => 'Project name: $name - $description';
}

