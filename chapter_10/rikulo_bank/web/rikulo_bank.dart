import 'dart:html';
import 'package:rikulo_ui/event.dart';
import 'package:rikulo_ui/view.dart';
import 'package:rikulo_bank/dwt_bank.dart';

BankAccount bac;
TextBox number, amount;
TextView owner, balance;
Button btn_deposit, btn_interest;

void main() {
  final View rootView = new View();
  rootView.style.cssText = "border: 1px solid #553; background-color: lime";
  number = new TextBox();
  owner = new TextView();
  owner.profile.width = "100";
  balance = new TextView();
  amount = new TextBox();
  btn_deposit = new Button("Deposit - Withdrawal");
  btn_deposit.profile.width = "150";
  btn_interest = new Button("Interest");

  number.on.change.listen((event) {
    readData();
    event.target.requestLayout();
  });

  btn_deposit.on.click.listen((event) {
    deposit(event);
    event.target.requestLayout();
  });

  btn_interest.on.click.listen((event) {
    interest(event);
    event.target.requestLayout();
  });

  rootView
    ..layout.text = "type: linear; orient: vertical"
    ..addChild(new TextView("BANK APP"))
    ..addChild(new TextView("Credit card number: "))
    ..addChild(number)
    ..addChild(new TextView("Owner: "))
    ..addChild(owner)
    ..addChild(new TextView("Balance: "))
    ..addChild(balance)
    ..addChild(new TextView("Amount: "))
    ..addChild(amount)
    ..addChild(btn_deposit)
    ..addChild(btn_interest)
    ..addToDocument();
}

readData() {
  // show data:
  var key = 'Bankaccount:${number.value}';
  if (!window.localStorage.containsKey(key)) {
    window.alert("Unknown bank account!");
    return;
  }
  // read data from local storage:
  String acc_json = window.localStorage[key];
  bac = new BankAccount.fromJsonString(acc_json);
  // show owner and balance:
  owner.text = "${bac.owner.name}";
  balance.text = "${bac.balance.toStringAsFixed(2)}";
}

deposit(e) {
  // read amount:
  // TODO: add exception handling:
  double money_amount = double.parse(amount.value);
  // call deposit on BankAccount object:
  if (money_amount >= 0) bac.deposit(money_amount);
  else bac.withdraw(money_amount);
  window.localStorage["Bankaccount:${bac.number}"] = bac.toJson();
  // show new amount:
  balance.text = "${bac.balance.toStringAsFixed(2)}";
  // disable refresh screen:
  e.preventDefault();
  e.stopPropagation();
}

interest(e) {
  bac.interest();
  window.localStorage["Bankaccount:${bac.number}"] = bac.toJson();
  balance.text = "${bac.balance.toStringAsFixed(2)}";
  e.preventDefault();
  e.stopPropagation();
}


