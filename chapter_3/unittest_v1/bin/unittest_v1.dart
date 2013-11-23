import 'package:unittest/unittest.dart';

main() {
  // var ba1;
  var ba1 = new BankAccount("John Gates","075-0623456-72", 1000.0);
  ba1.deposit(500.0);
  ba1.withdraw(300.0);
  ba1.deposit(136.0);
  // print('$ba1'); // Bank account from John Gates with number 075-0623456-72 and balance 1336.0
  // test balance after transactions:
  //  test('Account Balance after deposit and withdrawal', () {
  //    expect(ba1.balance, equals(1336.0));
  // });
  // v1:
  test('Account Balance after deposit and withdrawal', () => expect(ba1.balance, equals(1336.0)));
  test('Owner is correct', () => expect(ba1.owner, equals("John Gates")));
  test('Account Number is correct', () => expect(ba1.number, equals("075-0623456-72")));
  // v2: grouped version:
//  group('Bank Account tests', () {
//    test('Account Balance after deposit and withdrawal', () => expect(ba1.balance, equals(1336.0)));
//    test('Owner is correct', () => expect(ba1.owner, equals("John Gates")));
//    test('Account Number is correct', () => expect(ba1.number, equals("075-0623456-72")));
//  });
  // v3: setup and teardown:
//  group('Bank Account tests', () {
//    setUp(() {
//      ba1 = new BankAccount("John Gates","075-0623456-72", 1000.0);
//      ba1.deposit(500.0);
//      ba1.withdraw(300.0);
//      ba1.deposit(136.0);
//    });
//    tearDown(() {
//      ba1 = null;
//    });
//    test('Account Balance after deposit and withdrawal', () => expect(ba1.balance, equals(1336.0)));
//    test('Owner is correct', () => expect(ba1.owner, equals("John Gates")));
//    test('Account Number is correct', () => expect(ba1.number, equals("075-0623456-72")));
//   });
}

class BankAccount {
  String owner, number;
  double balance;
  DateTime dateCreated, dateModified;
  // constructors:
  BankAccount(this.owner, this.number, this.balance): dateCreated = new DateTime.now();
  BankAccount.sameOwner(BankAccount acc): owner = acc.owner;
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

