import 'dart:io';
import 'dart:async';

main() {
  var file = new File('bigfile.txt');
  file.readAsString()
    .then((text) => print(text))
    .catchError((e) => print(e));
// shorter version:
//  file.readAsString()
//    .then(print)
//    .catchError(print);

  // do other things while file is read in
// ...
}
