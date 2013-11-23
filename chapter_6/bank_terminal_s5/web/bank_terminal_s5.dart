import 'dart:html';
import 'package:bank_terminal_s5/bank_terminal.dart';

LabelElement owner, balance, error;
InputElement number, amount;
ButtonElement btn_other, btn_deposit, btn_withdrawal, btn_interest;
BankAccount bac;

void main() {
  bind_elements();
  attach_event_handlers();
  disable_transactions(true);
}

bind_elements() {
  owner = querySelector('#owner');
  balance = querySelector('#balance');
  number = querySelector('#number');
  btn_other = querySelector('#btn_other');
  amount = querySelector('#amount');
  btn_deposit = querySelector('#btn_deposit');
  btn_interest = querySelector('#btn_interest');
  error = querySelector('#error');
}

attach_event_handlers() {
  number.onInput.listen(readData);
  amount.onChange.listen(nonNegative);
  amount.onBlur.listen(nonNegative);
  btn_other.onClick.listen(clearData);
  btn_deposit.onClick.listen(changeBalance);
  btn_interest.onClick.listen(interest);
}

readData(Event e) {
  // show data:
  var key = 'Bankaccount:${number.value}';
  if (!window.localStorage.containsKey(key)) {
    error.innerHtml = "Unknown bank account!";
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
  // enable transactions part:
  disable_transactions(false);
}

clearData(Event e) => clear();

clear() {
  number.value = "";
  owner.innerHtml = "----------";
  balance.innerHtml = "0.0";
  number.focus();
  disable_transactions(true);
}

disable_transactions(bool off) {
  amount.disabled = off;
  btn_deposit.disabled = off;
  btn_interest.disabled = off;
}

nonNegative(Event e) {
  num input;
  try {
    input = double.parse(amount.value);
  } on FormatException catch(e) {
    window.alert("This is not a valid amount!");
    amount.focus();
  }
}

changeBalance(Event e) {
  // read amount:
  double money_amount = double.parse(amount.value);
  // call deposit on BankAccount object:
  if (money_amount >= 0) bac.deposit(money_amount);
  else bac.withdraw(money_amount);
  window.localStorage["Bankaccount:${bac.number}"] = bac.toJson();
  // show new amount:
  balance.innerHtml = "<b>${bac.balance.toStringAsFixed(2)}</b>";
  // disable refresh screen:
  e.preventDefault();
  e.stopPropagation();
}

interest(Event e) {
  bac.interest();
  window.localStorage["Bankaccount:${bac.number}"] = bac.toJson();
  balance.innerHtml = "<b>${bac.balance.toStringAsFixed(2)}</b>";
  e.preventDefault();
  e.stopPropagation();
}
