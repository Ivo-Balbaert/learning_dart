import 'dart:math';

void main() {
  var input = "47B9"; // value read from input, should be an integer
  // int inp = int.parse(input); // --> FormatException!
  // first attempt:
  try {
    int inp = int.parse(input);
  } on FormatException {
    print ('ERROR: You must input an integer!');
  }
  // general exception handler:
  try {
    int inp = int.parse(input);
  } on FormatException {
    print ('ERROR: You must input an integer!');
  } on Exception catch(e) { // Anything else that is an exception
    print('Unknown exception: $e');
  } catch(e) {              // No specified type, handles all
    print('Something really unknown: $e');
  } finally {
    print('OK, I have cleaned up the mess');
  }
  // throwing an exception:
  var radius = 8;
  var area = PI * pow(radius, 2);
  if (area > 200) { // area is 201.06192982974676
    throw 'This area is too big for me.';
  }
}
