part of bank_terminal;

class Person {
  String _name;

  String get name => _name;
  set name(value) {
    if (value != null && !value.isEmpty) _name = value;
  }

  Person(name) {
    this.name = name;
  }

  String toString() => 'Person: $name';
}

