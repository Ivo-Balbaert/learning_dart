part of bank_terminal;

class BankAccount extends Observable  {
  String __$_number;
  String get _number {
    if (__observe.observeReads) {
      __observe.notifyRead(this, __observe.ChangeRecord.FIELD, '_number');
    }
    return __$_number;
  }
  set _number(String value) {
    if (__observe.hasObservers(this)) {
      __observe.notifyChange(this, __observe.ChangeRecord.FIELD, '_number',
          __$_number, value);
    }
    __$_number = value;
  }
  Person owner;
  double _balance;
  int _pin_code;
  final DateTime date_created;
  DateTime date_modified;
  const double INTEREST = 5.0;

  @observable String get number => _number;
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

  int get pin_code => _pin_code;
  set pin_code(value) {
    if (value >= 1 && value <= 999999) _pin_code = value;
  }

  // constructors:
  BankAccount(this.owner, number, balance, pin_code):  date_created = new DateTime.now() {
    this.number = number;
    this.balance = balance;
    this.pin_code = pin_code;
    date_modified = date_created;
  }
  BankAccount.sameOwner(BankAccount acc): owner = acc.owner;
  BankAccount.sameOwnerInit(BankAccount acc): this(acc.owner, "000-0000000-00", 0.0, 0);

  BankAccount.fromJson(Map json):  date_created = DateTime.parse(json["creation_date"]) {
    this.number = json["number"];
    this.owner = new Person.fromJson(json["owner"]);
    this.balance = json["balance"];
    this.pin_code = json["pin_code"];
    this.date_modified = DateTime.parse(json["modified_date"]);
   }
  // methods:
  deposit(double amount) {
    balance += amount;
    date_modified = new DateTime.now();
  }

  withdraw(double amount) {
    balance -= amount;
    date_modified = new DateTime.now();
  }

  interest() {
    balance += balance * INTEREST/100.0;
  }

  String toString() => 'Bank account from $owner with number $number'
      ' and balance $balance';

  String toJson() {
    var acc = new Map<String, Object>();
    acc["number"] = number;
    acc["owner"] = owner.toJson();
    acc["balance"] = balance;
    acc["pin_code"] = pin_code;
    acc["creation_date"] = date_created.toString();
    acc["modified_date"] = date_modified.toString();
    var accs = stringify(acc); // use only once for the root object (here a bank account)
    return accs;
  }
}


//@ sourceMappingURL=bank_account.dart.map