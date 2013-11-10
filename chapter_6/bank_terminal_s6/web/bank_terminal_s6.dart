library bank_terminal;

import 'dart:html';
import 'dart:convert';

part '../model/bank_account.dart';
part '../model/person.dart';

List account_nos;
String select, data;
SelectElement sel;
TableElement table;
BankAccount bac;

void main() {
  readLocalStorage();
  constructPage();
  sel.onChange.listen(showAccount);
}

readLocalStorage() {
  account_nos = [];
  for (var key in window.localStorage.keys) {
    if (key.substring(0,4) == "Bank")
      account_nos.add(key.substring(12)); // extract account number
  }
}

constructPage() {
// make dropdown list and fill with data:
  var el = new Element.html(constructSelect());
  document.body.children.add(el);
// prepare html table for account data:
  var el1 = new Element.html(constructTable());
  document.body.children.add(el1);
  sel = querySelector('#accounts');
  table = querySelector('#accdata');
  table.classes.remove('border');
}

String constructSelect() {
  var sb = new StringBuffer();
  sb.write('<select id="accounts">');
  sb.write('<option selected>Select an account no:</option>');
  account_nos.forEach( (acc) => sb.write('<option>$acc</option>')  );
  sb.write('</select>');
  return sb.toString();
}

String constructTable() {
  var sb = new StringBuffer();
  sb.write('<table id="accdata" class="border">');
  sb.write('</table>');
  return sb.toString();
}

showAccount(Event e) {
  // remove previous table data:
  table.children.clear();
  table.classes.remove('border');
  // get selected number:
  sel = e.currentTarget;
  if (sel.selectedIndex >= 1) { // an account was chosen
    var accountno = account_nos[sel.selectedIndex - 1];
    var key = 'Bankaccount:$accountno';
    String acc_json = window.localStorage[key];
    bac = new BankAccount.fromJson(JSON.decode(acc_json));
    // show data:
    table.classes.add('border');
    constructTrows();
  }
}

constructTrows() {
  var sb = new StringBuffer();
   sb.write('<p><tr><b><td>Owner:</td></b>   <td>${bac.owner.name}</td></tr><br/>');
  sb.write('<tr><b><td>Address:</td></b>     <td>${bac.owner.address}</td></tr><br/>');
  sb.write('<tr><b><td>Email:</td></b>       <td>${bac.owner.email}</td></tr><br/>');
  sb.write('<tr><b><td>Gender:</td></b>      <td>${bac.owner.gender}</td></tr><br/>');
  sb.write('<tr><b><td>Birthdate:</td></b>   <td>${bac.owner.date_birth}</td></tr><br/>');
  sb.write('<tr><b><td>Balance:</td></b>     <td>${bac.balance.toStringAsFixed(2)}</td></tr><br/>');
  sb.write('<tr><b><td>Pin code:</td></b>    <td>${bac.pin_code}</td></tr><br/>');
  sb.write('<tr><b><td>Created on:</td></b>  <td>${bac.date_created}</td></tr><br/>');
  sb.write('<tr><b><td>Modified on:</td></b> <td>${bac.date_modified}</td></tr></p>');
  data = sb.toString();
  Element trows = new Element.html(data);
  table.children.add(trows);
}