import 'dart:html';
import 'package:bank_terminal_s4/bank_terminal.dart';

LabelElement owner, balance, error;
InputElement number, amount;
ButtonElement btn_other, btn_deposit, btn_withdrawal, btn_interest;
BankAccount bac;

void main() {
  bind_elements();
  attach_event_handlers();
}

bind_elements() {
  owner = querySelector('#owner');
  balance = querySelector('#balance');
  number = querySelector('#number');
  btn_other = querySelector('#btn_other');
  error = querySelector('#error');
}

attach_event_handlers() {
  number.onInput.listen(readData);
  btn_other.onClick.listen(clearData);
}

readData(Event e) {
  // show data:
  var key = 'Bankaccount:${number.value}';
  if (!window.localStorage.containsKey(key)) {
    error.innerHtml = "Unknown bank account!";
    owner.innerHtml = "----------";
    balance.innerHtml = "0.0";
    number.focus();
    return;
  }
  error.innerHtml = "";
  // read data from local storage:
  String acc_json = window.localStorage[key];
  bac = new BankAccount.fromJsonString(acc_json);
  // show owner and balance:
  owner.innerHtml = "<b>${bac.owner.name}</b>";
  balance.innerHtml = "<b>${bac.balance.toStringAsFixed(2)}</b>";
}

clearData(Event e) {
  number.value = "";
  owner.innerHtml = "----------";
  balance.innerHtml = "0.0";
  number.focus();
}