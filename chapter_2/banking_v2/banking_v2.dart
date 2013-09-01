main() {
  var ba = new BankAccount("John Gates","075-0623456-72", 1000.0);
  assert(ba is BankAccount);
  print('$ba');
  // without toString(): Instance of 'BankAccount'
  // with toString(): Bank account from John Gates with number 075-0623456-72 and balance 1000.0
  print('Bank account created at: ${ba.dateCreated}');
  ba.withdraw(100.0);
  print("Balance after withdrawal:\t ${ba.balance} \$"); // 900.0
  print('Account balance modified at: ${ba.dateModified}');
  print('${ba.dateModified.weekday}');
  // cascading notation:
  ba
    ..balance = 5000.0  // no ;
    ..withdraw(100.0)
    ..deposit(250.0);   // only the last statement has a ;
  print("Balance:\t ${ba.balance} \$");  // 5150.0
}

class Person {
  // Person properties and methods
  String name, address;
  // ...
}

class BankAccount {
  String owner, number;
  // Person owner;
  double balance;
  DateTime dateCreated, dateModified;
  // constructor:
//  BankAccount(this.owner, this.number, this.balance)  {
//    dateCreated = new DateTime.now();
//  }
//  // version with initializer list:
  BankAccount(this.owner, this.number, this.balance): dateCreated = new DateTime.now();
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
}
