library bank_terminal;

import 'dart:html';
import 'dart:convert';
import 'package:mdv/mdv.dart' as mdv;

part 'model/bank_account.dart';
part 'model/person.dart';

var in_amount;
double amount;
BankAccount bac;
List accounts;

void main() {
  mdv.initialize();
  var jw = new Person("John Witgenstein", "Session street 675, 9000 Gent, Belgium",
      "johnw@aho.be", "M", DateTime.parse("1963-02-17 00:00:00.000"));
  bac = new BankAccount(jw, "456-0692322-12", 1500.0, 1234);
  querySelector("#account").model = bac;
}