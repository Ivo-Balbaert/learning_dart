main() {
  var ba = new BankAccount("John Gates","075-0623456-72", 1000.0);
  print('$ba');
  // without toString(): Instance of 'BankAccount'
  // with toString(): Bank account from John Gates with number 075-0623456-72 and balance 1000.0
  print('Bank account created at: ${ba.dateCreated}');
  ba.withdraw(100.0);
  print("Balance after withdrawal:\t ${ba.balance} \$");
  print('Account balance modified at: ${ba.dateModified}');
}

/**
 * A bank account has an [owner], is identified by a [number]
 * and has an amount of money called [balance].
 * The balance is changed through methods [deposit] and [withdraw].
 */
class BankAccount {
  String owner, number;
  double balance;
  DateTime dateCreated, dateModified;

  BankAccount(this.owner, this.number, this.balance)  {
    dateCreated = new DateTime.now();
  }

 /// An amount of money is added to the balance.
    deposit(double amount) {
    balance += amount;
    dateModified = new DateTime.now();
  }

 /// An amount of money is subtracted from the balance.
    withdraw(double amount) {
    balance -= amount;
    dateModified = new DateTime.now();
  }

    String toString() => 'Bank account from $owner with number $number'
        ' and balance $balance';
}
