import 'dart:html';
import 'package:bee/components/loading.dart';
import 'package:bee/components/overlay.dart';
import 'package:bee/components/popover.dart';
import 'package:bee/components/secret.dart';
import 'package:bee/utils/html_helpers.dart';

void main() {
  query("#sample_text_id")
    ..text = "Click me!"
    ..onClick.listen(reverseText);
}

void reverseText(MouseEvent event) {
  var text = query("#sample_text_id").text;
  var buffer = new StringBuffer();
  for (int i = text.length - 1; i >= 0; i--) {
    buffer.write(text[i]);
  }
  query("#sample_text_id").text = buffer.toString();
}
