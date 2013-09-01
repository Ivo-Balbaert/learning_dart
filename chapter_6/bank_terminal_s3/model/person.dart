part of bank_terminal;

class Person {
  // Person properties:
  String _name, address, _email, _gender;
  DateTime _date_birth;

  String get name => _name;
  set name(value) {
    if (value != null && !value.isEmpty) _name = value;
  }

  String get email => _email;
  set email(value) {
    if (value != null && !value.isEmpty) _email = value;
  }

  String get gender => _gender;
  set gender(value) {
    if (value == 'M' || value == 'F') _gender = value;
  }

  DateTime get date_birth =>  _date_birth;
  set date_birth(value) {
    DateTime now = new DateTime.now();
    if (value.isBefore(now)) _date_birth = value;
  }

  // constructor:
  Person(name, this.address, email, gender, date_birth) {
    this.name = name;
    this.email = email;
    this.gender = gender;
    this.date_birth = date_birth;
  }
   // methods:
  String toString() => 'Person: $name, $gender';

  Map<String, Object> toJson() {
    var per = new Map<String, Object>();
    per["name"] = name;
    per["address"] = address;
    per["email"] = email;
    per["gender"] = gender;
    per["birthdate"] = date_birth.toString();
    return per;
  }
}

