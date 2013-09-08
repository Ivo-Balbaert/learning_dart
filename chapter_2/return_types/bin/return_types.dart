// different alternatives are commented out
main() {
  print(display('Hello')); // Message: Hello.   null   (1)
  print(displayStr('Hello')); // Message: Hello.       (2)
  print(displayStrShort('Hello')); // Message: Hello.
  print(display(display("What's up?")));            // (3)
  print('${isOdd(13)}');    // true
  [1,2,3,4,5].where(isOdd).toList(); //      [1, 3, 5] (4)
}

display(message) => print('Message: $message.');
//display(message) {
//  print('Message: $message.');
//}

displayStr(message) {
  return 'Message: $message.';
}

//String displayStr(message) {
//  return 'Message: $message.';
//}

displayStrShort(message) => 'Message: $message.';
// String displayStrShort(message) => 'Message: $message.';

isOdd(n) => n % 2 == 1;