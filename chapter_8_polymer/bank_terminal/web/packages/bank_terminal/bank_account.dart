part of bank_terminal;

class BankAccount {
  String _number;
  Person owner;
  double _balance;

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

  BankAccount(this.owner, number, balance) {
    this.number = number;
    this.balance = balance;
  }

  transact(double amount) {
    balance += amount;
  }

  String toString() => 'Bank account from $owner with number $number'
      ' and balance $balance';
}

