import 'dart:html';
import 'package:polymer/polymer.dart';

@CustomTag('bank-account-form')
class BankAccountForm extends PolymerElement {
  @published var errormessage = "";
  // @observable var bac;
  @published var bac;
  @published String in_amount = "25.0";
  var accounts = toObservable(["052-0692562-12", "235-4523915-98", "456-0692322-12",
                           "789-2194366-45"]);
  double amount = 0.0;
//
//  created() {
//    super.created();
//    // query("#tmpl2").model = bac; // the null object does not have a setter model =
//  }

  // balance = onPropertyChange(this, #bac, () => notifyProperty(this, #balance));

  // @published int get balance => bac.balance;
//  bacChanged(bac) {
//    notifyProperty(this, #bac.balance); // method not defined for class BAF
//  }

  deposit(Event e, var detail, Node target) {
    errormessage = "";
    if (!checkAmount(e)) return;
    // call deposit on BankAccount object:
    if (amount >= 0) bac.deposit(amount);
    else bac.withdraw(amount);
    // even the following line does not change screen!
    // bac.balance = 125.0;
    in_amount = '0.0';
    // deliverChanges(); doesn't work
    // neither does: input value = {{}}
    // bacChanged(bac);
    // notifyProperty(this, #bac.balance);
    disableRefresh(e);
  }

  interest(Event e, var detail, Node target) {
    bac.interest();
    disableRefresh(e);
  }

  disableRefresh(e) {
    e.preventDefault();
    e.stopPropagation();
  }

  checkAmount(e) {
    // check amount:
    try {
      amount = double.parse(in_amount);
    } on FormatException catch(ex) {
      errormessage = "This is not a valid amount!";
      disableRefresh(e);
      return false;
    }
    return true;
  }
}

