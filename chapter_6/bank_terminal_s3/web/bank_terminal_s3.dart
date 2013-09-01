library bank_terminal;

import 'dart:html';
import 'dart:json';

part '../model/bank_account.dart';
part '../model/person.dart';

InputElement name, address, email, birth_date, gender;
InputElement number, balance, pin_code ;
ButtonElement btn_create;

void main() {
  // bind variables to DOM elements:
  name = query('#name');
  address = query('#address');
  email = query('#email');
  birth_date = query('#birth_date');
  gender = query('#gender');
  number = query('#number');
  balance = query('#balance');
  pin_code = query('#pin_code');
  btn_create = query('#btn_create');
  // attach event handlers:
  // checks for not empty in onBlur event:
  name.onBlur.listen(notEmpty);
  email.onBlur.listen(notEmpty);
  number.onBlur.listen(notEmpty);
  pin_code.onBlur.listen(notEmpty);
  // other checks:
  birth_date.onChange.listen(notInFuture);
  birth_date.onBlur.listen(notInFuture);
  gender.onChange.listen(wrongGender);
  balance.onChange.listen(nonNegative);
  balance.onBlur.listen(nonNegative);
  // create the Person and Bank Account objects, and store them in local storage:
  btn_create.onClick.listen(storeData);
}

notEmpty(Event e) {
  InputElement inel = e.currentTarget as InputElement;
  var input = inel.value;
  if (input == null || input.isEmpty) {
    window.alert("You must fill in the field ${inel.id}!");
   inel.focus();
  }
}

notInFuture(Event e) {
  DateTime birthDate;
  try {
    birthDate = DateTime.parse(birth_date.value);
  } on ArgumentError catch(e) {
    window.alert("This is not a valid date!");
    birth_date.focus();
    return;
  }
  DateTime now = new DateTime.now();
  if (!birthDate.isBefore(now)) {
    window.alert("The birth date cannot be in the future!");
    birth_date.focus();
  }
}

wrongGender(Event e) {
  var sex = gender.value;
  if (sex != 'M' && sex != 'F') {
    window.alert("The gender must be either M (male) or F (female)!");
    gender.focus();
  }
}

nonNegative(Event e) {
  num input;
  try {
    input = double.parse(balance.value);
  } on FormatException catch(e) {
    window.alert("This is not a valid balance!");
    balance.focus();
    return;
  }
  if (input < 0) {
    window.alert("The balance cannot be negative!");
    balance.focus();
  }
}

storeData(Event e) {
  // creating the objects:
  Person p = new Person(name.value, address.value, email.value, gender.value,
      DateTime.parse(birth_date.value));
  BankAccount bac = new BankAccount(p, number.value, double.parse(balance.value),
      int.parse(pin_code.value));
  // store data in local storage:
  try {
    window.localStorage["Bankaccount:${bac.number}"] = bac.toJson();
    window.alert("Bank account data stored in the browser.");
  } on Exception catch (ex) {
    window.alert("Data not stored: Local storage has been deactivated!");
  }
}