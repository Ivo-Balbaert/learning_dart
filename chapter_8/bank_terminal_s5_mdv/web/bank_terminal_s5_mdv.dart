library bank_terminal;

import 'dart:html';
import 'dart:json';
import 'package:web_ui/web_ui.dart';

part 'model/bank_account.dart';
part 'model/person.dart';

var in_amount;
double amount;
BankAccount bac;
List accounts;

void main() {
  Person jw = new Person("John Witgenstein", "Session street 675, 9000 Gent, Belgium",
      "johnw@aho.be", "M", DateTime.parse("1963-02-17 00:00:00.000"));
  bac = new BankAccount(jw, "456-0692322-12", 1500.0, 1234);
  accounts = toObservable(["052-0692562-12", "235-4523915-98", "456-0692322-12",
                   "789-2194366-45"]);
}

deposit(e) {
  if (!checkAmount()) return;
  // call deposit on BankAccount object:
  if (amount >= 0) bac.deposit(amount);
  else bac.withdraw(amount);
  in_amount = '0.0';
  disableRefresh(e);
}

interest(e) {
  bac.interest();
  disableRefresh(e);
}

disableRefresh(e) {
  e.preventDefault();
  e.stopPropagation();
}

checkAmount() {
  // check amount:
  try {
    amount = double.parse(in_amount);
  } on FormatException catch(e) {
    window.alert("This is not a valid amount!");
    return false;
  }
  return true;
}





