import 'dart:html';
import 'package:polymer/polymer.dart';

@CustomTag('bank-account')
class BankAccount extends PolymerElement {
  @published var bac;
  @published double balance;
  double amount = 0.0;

  BankAccount.created() : super.created() {  }

  enteredView() {
    super.enteredView();
    balance = bac.balance;
  }

  transact(Event e, var detail, Node target) {
    InputElement amountInput = shadowRoot.querySelector("#amount");
    if (!checkAmount(amountInput.value)) return;
    bac.transact(amount);
    balance = bac.balance;
  }

  enter(KeyboardEvent  e, var detail, Node target) {
    if (e.keyCode == KeyCode.ENTER) {
      transact(e, detail, target);
    }
  }

  checkAmount(String in_amount) {
    try {
      amount = double.parse(in_amount);
    } on FormatException catch(ex) {
      return false;
    }
    return true;
  }
}