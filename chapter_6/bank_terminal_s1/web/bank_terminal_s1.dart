library bank_terminal;
import 'dart:html';

part '../model/bank_account.dart';
part '../model/person.dart';

void main() {
  ButtonElement btn_create = query('#btn_create');
  btn_create.onClick.listen(create_account);
}

create_account(Event e) {
  // window.alert("I am in create account!");
}

