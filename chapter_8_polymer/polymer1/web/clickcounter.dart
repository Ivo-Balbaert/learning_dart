import 'package:polymer/polymer.dart';

@CustomTag('click-counter')
class ClickCounter extends PolymerElement {
  @observable int count = 0;

  void increment() {
    count++;
  }
}

