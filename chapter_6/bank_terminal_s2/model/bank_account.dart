part of bank_terminal;

class BankAccount {
  String _number;
  Person owner;
  double _balance;
  int _pin_code;
  final DateTime date_created;
  DateTime date_modified;

  String get number => _number;
  set number(value) {
    if (value == null || value.isEmpty) return;
    // test the format:
    RegExp exp = new RegExp(r"[0-9]{3}-[0-9]{7}-[0-9]{2}");
    if (exp.hasMatch(value)) _number = value;
  }

  double get balance => _balance;
  set balance(value) {
    if (value >= 0) _balance = value;
  }

  int get pin_code => pin_code;
  set pin_code(value) {
    if (value >= 1 && value <= 999999) _pin_code = value;
  }

  // constructors:
//  BankAccount(this.owner, this.number, this.balance, this.pin_code):
//            date_created = new DateTime.now();
  BankAccount(this.owner, number, balance, pin_code):  date_created = new DateTime.now() {
    this.number = number;
    this.balance = balance;
    this.pin_code = pin_code;
  }
  BankAccount.sameOwner(BankAccount acc): owner = acc.owner, date_created = new DateTime.now();
  BankAccount.sameOwnerInit(BankAccount acc): this(acc.owner, "000-0000000-00", 0.0, 0);

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

