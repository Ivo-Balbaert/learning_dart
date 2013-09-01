import 'dart:convert';

var jsonStr1 = '''
{
    "owner": "John Gates",
    "number": "075-0623456-72",
    "balance": 1000.0
}
''';
var jsonStr2 = '''
[
  {
      "owner": "John Gates",
      "number": "075-0623456-72",
      "balance": 1000.0
  },
  {
      "owner": "Bill O'Connor",
      "number": "081-0731645-91",
      "balance": 2500.0
  }
]
''';
var bankAccounts = [{ "owner": "John Gates","number": "075-0623456-72",
                      "balance": 1000.0 },
                    { "owner": "Bill O'Connor", "number": "081-0731645-91",
                      "balance": 2500.0 }];
main() {
  // print('$jsonString');
  // encoding a Dart object (here a List of Maps) to a JSON string:
  var jsonText = JSON.encode(bankAccounts);
  print('$jsonText'); // all white space is removed
  // decoding a JSON string into a Dart object:
  var obj = JSON.decode(jsonText);
  assert(obj is List);
  assert(obj[0] is Map);
  assert(obj[0]['number']=="075-0623456-72");

  var ba1 = new BankAccount("John Gates","075-0623456-72", 1000.0);
  var json = JSON.encode(ba1);
  print('$json');
}

class BankAccount {
  String owner, number;
  double balance;
  DateTime dateCreated, dateModified;
  // constructors:
  BankAccount(this.owner, this.number, this.balance): dateCreated = new DateTime.now();
  // named constructor:
//  BankAccount.sameOwner(BankAccount acc)  {
//    owner = acc.owner;
//  }
  // shorter version with initializer list:
  BankAccount.sameOwner(BankAccount acc): owner = acc.owner;
  // redirecting constructor:
  BankAccount.sameOwner2(BankAccount acc): this(acc.owner, "000-0000000-00", 0.0);

  // methods:
    deposit(double amount) {
    balance += amount;
    dateModified = new DateTime.now();
  }

  withdraw(double amount) {
    balance -= amount;
    dateModified = new DateTime.now();
  }

  String toString() => 'Bank account from $owner with number $number'
      ' and balance $balance';

  String toJson() {
    return '{"owner":"$owner", "number":"$number", "balance: "$balance"}';
  }
}