import 'dart:html';
import 'package:rikulo_ui/event.dart';
import 'package:rikulo_ui/view.dart';

void main() {
  var root = new View()
    ..layout.type = "linear"      // specify layout
    ..layout.orient = "vertical"
    ..style.cssText = "font-size: 14px; text-align: center"  // CSS
    ..addChild(new TextView("Credit card number: "))
    ..addChild(new TextBox())
    ..addChild(new TextView("Verified: "))
    ..addChild(new CheckBox())
    ..addToDocument();            //make it available to the browser

  var hello = new Button("Support our work!")
    ..on.click.listen((event) {   // attach click event handler
      (event.target as Button).text = "Thanks!!";
       event.target.requestLayout();  // redraw screen
  });
  root.addChild(hello);        // attach to root view
}


