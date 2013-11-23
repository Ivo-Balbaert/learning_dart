import 'dart:html';
import 'package:dquery/dquery.dart';

void main() {
  ElementQuery $elems = $('#sample_text_id');
  $('#sample_text_id')[0]
    ..text = "Click me!"
    ..onClick.listen(reverseText);

  $('#btn').on('click', (DQueryEvent e) {
    $('#btn')[0]
    ..text = "Don't do this!";
  });
}

void reverseText(MouseEvent event) {
  var text = querySelector("#sample_text_id").text;
  var buffer = new StringBuffer();
  for (int i = text.length - 1; i >= 0; i--) {
    buffer.write(text[i]);
  }
  querySelector("#sample_text_id").text = buffer.toString();
}
