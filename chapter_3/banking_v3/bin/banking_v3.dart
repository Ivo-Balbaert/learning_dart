main() {
  var ba1 = new BankAccount("John Gates","075-0623456-72", 1000.0);
  print('$ba1'); // Bank account from John Gates with number 075-0623456-72 and balance 1000.0
  var ba2 = new BankAccount.sameOwner(ba1);
  print('$ba2'); // Bank account from John Gates with number null and balance null
  var ba3 = new BankAccount.sameOwner2(ba1);
  print('$ba3'); // Bank account from John Gates with number 000-0000000-00 and balance 0.0
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
}
