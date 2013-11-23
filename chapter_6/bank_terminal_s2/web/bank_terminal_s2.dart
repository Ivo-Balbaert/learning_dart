import 'dart:html';
import 'package:bank_terminal_s2/bank_terminal.dart';

InputElement name, address, email, birth_date, gender;
InputElement number, balance, pin_code;
LabelElement lbl_error;
ButtonElement btn_create;

void main() {
  // bind variables to DOM elements:
  name = querySelector('#name');
  address = querySelector('#address');
  email = querySelector('#email');
  birth_date = querySelector('#birth_date');
  gender = querySelector('#gender');
  number = querySelector('#number');
  balance = querySelector('#balance');
  pin_code = querySelector('#pin_code');
  btn_create = querySelector('#btn_create');
  lbl_error = querySelector('#error');
  lbl_error.text = "";
  lbl_error.style..color = "red";
  // attach event handlers:
  // window.onLoad.listen((e) => name.focus());
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
  // create the Person and Bank Account objects:
  btn_create.onClick.listen(storeData);
}

notEmpty(Event e) {
  InputElement inel = e.currentTarget as InputElement;
  var input = inel.value;
  if (input == null || input.isEmpty) {
    // window.alert("You must fill in the field ${inel.id}!");
    lbl_error.text = "You must fill in the field ${inel.id}!";
    inel.focus();
  }
}

notInFuture(Event e) {
  DateTime birthDate;
  try {
    birthDate = DateTime.parse(birth_date.value);
  } on ArgumentError catch(e) {
    // window.alert("This is not a valid date!");
    lbl_error.text = "This is not a valid date!";
    birth_date.focus();
    return;
  }
  DateTime now = new DateTime.now();
  if (!birthDate.isBefore(now)) {
    // window.alert("The birth date cannot be in the future!");
    lbl_error.text = "The birth date cannot be in the future!";
    birth_date.focus();
  }
}

wrongGender(Event e) {
  var sex = gender.value;
  if (sex != 'M' && sex != 'F') {
    // window.alert("The gender must be either M (male) or F (female)!");
    lbl_error.text = "The gender must be either M (male) or F (female)!";
    gender.focus();
  }
}

nonNegative(Event e) {
  num input;
  try {
    input = double.parse(balance.value);
  } on FormatException catch(e) {
    // window.alert("This is not a valid balance!");
    lbl_error.text = "This is not a valid balance!";
    balance.focus();
    return;
  }
  if (input < 0) {
    // window.alert("The balance cannot be negative!");
    lbl_error.text = "The balance cannot be negative!";
    balance.focus();
  }
}

storeData(Event e) {
  // creating the objects:
  Person p = new Person(name.value, address.value, email.value, gender.value,
      DateTime.parse(birth_date.value));
  try {
  BankAccount bac = new BankAccount(p, number.value, double.parse(balance.value),
      int.parse(pin_code.value));
  }
  catch(e) {
    window.alert(e.toString());
  }
}

/* to check:
 *
 * 1) when the web page is loaded the cursor remains in the address bar, a
 * new refresh is necessary to focus on name;
 * window.onLoad does not fix this
 * 2) when Blur and then Change event goes off, the same message appears twice
 *
*/


