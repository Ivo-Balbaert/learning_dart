part of bank_terminal;

class BankAccount {
  String number;
  Person owner;
  double balance;
  final DateTime date_created;
  DateTime date_modified;

  // constructors:
  BankAccount(this.owner, this.number, this.balance): date_created = new DateTime.now();
  BankAccount.sameOwner(BankAccount acc): owner = acc.owner, date_created = new DateTime.now();
  BankAccount.sameOwnerInit(BankAccount acc): this(acc.owner, "000-0000000-00", 0.0);

  // methods:
  deposit(double amount) {
    balance += amount;
    date_modified = new DateTime.now();
  }

  withdraw(double amount) {
    balance -= amount;
    date_modified = new DateTime.now();
  }

  String toString() => 'Bank account from $owner with number $number'
      ' and balance $balance';
}

