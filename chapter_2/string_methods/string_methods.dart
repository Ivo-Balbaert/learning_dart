main() {
// Check for an empty string.
  var owner = '';
  assert(owner.isEmpty);
  assert("".isEmpty == true);
// Strings with only white space are not empty.
  assert('  '.isEmpty == false);
// Trim a string.
  assert('\thello  '.trim() == 'hello');
// length:
  assert('Google'.length == 6);

// startsWith, endsWith, contains
  var fullName = 'Larry Page';
  assert(fullName.startsWith('La'));
  assert(fullName.endsWith('age'));
  assert(fullName.contains('y P'));

// replaceAll, strings are immutable
  var composer = 'Johann Sebastian Bach';
  var s = composer.replaceAll('a', '-');
  print(s); // Joh-nn Seb-sti-n B-ch
  assert(s != composer); // composer didn't change.

// Get the character (as a string) by index.
  var lang = "Dart";
  assert(lang[0] == "D");
// find the location of a string inside a string.
  assert(lang.indexOf("ar") == 1);

// extracting data from a string
  assert("20000 rabbits".substring(9, 13) == 'bits');

// use StringBuffer instead of frequent concatenation
  var sb = new StringBuffer();
  sb.write("Use a StringBuffer ");
  sb.writeAll(["for ", "efficient ", "string ", "creation "]);
  sb.write("if you are ");
  sb.write("building lots of strings.");
  var fullString = sb.toString();
  print('$fullString');
  assert(fullString ==
      'Use a StringBuffer for efficient string creation '
      'if you are building lots of strings.');
  sb.clear(); // sb is empty again
  // sb = new StringBuffer();  // sb is empty again
  assert(sb.toString() == '');
// splitting a String:
  var number = "075-0623456-72";
  var parts = number.split('-');
  print('$parts'); // [075, 0623456, 72]
}
