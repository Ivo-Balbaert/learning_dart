void main() {
 // if else if:
  var n = 25;
  if (n < 10) {
    print('1 digit number: $n');
  } else if (n >=  10 && n < 100){
    print('2+ digit number: $n'); // 2+ digit number: 25
  } else {
    print('3 or more digit number: $n');
  }
// ternary operator:
  num rabbitCount = 16758;
  (rabbitCount > 20000) ? print('enough for this year!') : print('breed on!');
  // breed on!

// type - test:
  var ba1, ba2;
  ba1 = new BankAccount("Jeff", "5768-346-89", 758.0);
  if (ba1 is BankAccount) ba1.deposit(42.0);
  print('${ba1.balance}'); // 800.0
  // (ba2 as BankAccount).deposit(100.0); <-- NoSuchMethodError
  if (ba2 is BankAccount) {
    (ba2 as BankAccount).deposit(100.0);
    print('deposited 100 on ba2'); // statement not reached
  } else {
    print('ba2 is not a BankAccount'); // ba2 is not a BankAccount
  }
// switch-case:
  switch(ba1.owner) {
    case 'Jeff':
        print('Jeff is the bank account owner'); // this is printed
        break;
    case 'Mary':
        print('Mary is the bank account owner');
        break;
    default:
      print('The bank account owner is not Jeff, nor Mary');
  }
// for-loop:
  var langs = ["Java","Python","Ruby", "Dart"];
  for (int i = 0; i < langs.length; i++) {
    print('${langs[i]}');
  }

  var s = '';
  var numbers = [0, 1, 2, 3, 4, 5, 6, 7];
  for (var n in numbers) {
    s = '$s$n ';
  }
  print(s);  // 0 1 2 3 4 5 6 7
// while-loop:
  while (rabbitCount <= 20000) {
    print('keep breeding');
    rabbitCount += 4;
  }
  print('$rabbitCount');
  rabbitCount = 19000;
  while (true) {
    print('keep breeding');
    if (rabbitCount > 20000) break;
    rabbitCount += 4;
  }
  s = '';
  for (var n in numbers) {
    if (n % 2 == 0) continue; // skip even numbers
    s = '$s$n ';
  }
  print('$s');  // 1 3 5 7
}

class BankAccount {
  String owner, number;
  double balance;
  DateTime dateCreated, dateModified;
  // constructor:
  BankAccount(this.owner, this.number, this.balance)  {
    dateCreated = new DateTime.now();
  }
  // methods:
    deposit(double amount) {
    balance += amount;
    dateModified = new DateTime.now();
  }
}