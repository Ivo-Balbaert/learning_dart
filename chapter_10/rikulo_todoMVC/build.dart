import 'dart:io' show Options;
import 'package:rikulo_uxl/uc.dart' show build;

void main() {
  // invoke UXL auto-compile
  build(new Options().arguments);
}
