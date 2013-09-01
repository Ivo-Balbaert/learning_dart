void main() {
  final name = 'John';
  // var name = 'Mia';  // error: duplicate local variable name
  // final String name = 'John';
  // name = 'Lucy'; // warning: cannot assign value to final variable name

  const SECINMIN = 60;
  const SECINDAY = SECINMIN * 60 * 24;
  print('$SECINDAY');  // 86400

  int daysInWeek = 7;
  final fdaysInYear = daysInWeek * 52;
  // const DAYSINYEAR =  daysInWeek * 52; // error: expected constant expression
}
