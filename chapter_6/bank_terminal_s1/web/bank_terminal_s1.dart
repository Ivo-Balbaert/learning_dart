import 'dart:html';
//import 'package:bank_terminal_s1/bank_terminal.dart';

void main() {
  ButtonElement btn_create = querySelector('#btn_create');
  btn_create.onClick.listen(create_account);
}

create_account(Event e) {
  // window.alert("I am in create account!");
}

