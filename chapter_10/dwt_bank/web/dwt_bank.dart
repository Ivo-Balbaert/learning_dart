library bank_terminal;

import 'dart:html';
import 'package:dart_web_toolkit/ui.dart' as ui;
import 'package:dart_web_toolkit/i18n.dart' as i18n;
import 'package:dart_web_toolkit/event.dart' as event;
import 'dart:json';

part '../model/bank_account.dart';
part '../model/person.dart';

ui.TextBox number;
ui.Label owner, balance;
ui.IntegerBox amount;
ui.Button btn_deposit, btn_interest;
BankAccount bac;

void main() {
  ui.CaptionPanel panel = new ui.CaptionPanel("BANK APP");
  panel.getElement().style.border = "3px solid #00c";

  ui.FlexTable layout = new ui.FlexTable();
  layout.setCellSpacing(6);
  ui.FlexCellFormatter cellFormatter = layout.getFlexCellFormatter();

// Add a title to the form
  layout.setHtml(0, 0, "Enter your account number<br> and transaction amount");
  cellFormatter.setColSpan(0, 0, 2);
  cellFormatter.setHorizontalAlignment(0, 0, i18n.HasHorizontalAlignment.ALIGN_LEFT);

// Add some standard form options
  layout.setHtml(1, 0, "Number:");
  number = new ui.TextBox();
  number.addValueChangeHandler(new event.ValueChangeHandlerAdapter((event.ValueChangeEvent event) {
    readData();
   }));
  layout.setWidget(1, 1, number);
  layout.setHtml(2, 0, "Owner:");
  owner = new ui.Label("");
  layout.setWidget(2, 1, owner);
  layout.setHtml(3, 0, "Balance:");
  balance = new ui.Label("");
  layout.setWidget(3, 1, balance);
  layout.setHtml(4, 0, "Amount:");
  amount = new ui.IntegerBox();
  layout.setWidget(4, 1, amount);
  btn_deposit = new ui.Button(
      "Deposit - Withdrawal", new event.ClickHandlerAdapter((event.ClickEvent event) {
       deposit(event);
      }));
  layout.setWidget(5, 0, btn_deposit);
  btn_interest = new ui.Button(
      "Add Interest", new event.ClickHandlerAdapter((event.ClickEvent event) {
        interest(event);
      }));
  layout.setWidget(5, 1, btn_interest);

  panel.setContentWidget(layout);
  ui.RootLayoutPanel.get().add(panel);
}

readData() {
  // show data:
  var key = 'Bankaccount:${number.text}';
  if (!window.localStorage.containsKey(key)) {
    window.alert("Unknown bank account!");
    return;
  }
  // read data from local storage:
  String acc_json = window.localStorage[key];
  bac = new BankAccount.fromJson(parse(acc_json));
  // show owner and balance:
  owner.text = "${bac.owner.name}";
  balance.text = "${bac.balance.toStringAsFixed(2)}";
}

deposit(e) {
  // read amount:
  // TODO: add exception handling:
  double money_amount = double.parse(amount.text);
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
