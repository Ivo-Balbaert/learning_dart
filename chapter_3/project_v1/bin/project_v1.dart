main() {
  var p1 = new Project();
  p1.name = 'Breeding';
  p1.description = 'Managing the breeding of animals';
  print('$p1');
  // prints: Project name: Breeding - Managing the breeding of animals
}

class Project {
  String name, description;

  toString() => 'Project name: $name - $description';
}