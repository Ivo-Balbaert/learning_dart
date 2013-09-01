library widget;

import 'dart:async';
import 'dart:html';
import 'package:web_ui/web_ui.dart';
import 'package:widget/effects.dart';

abstract class SwapComponent {

  int get activeItemIndex;
  Element get activeItem;
  List<Element> items;

  Future<bool> showItemAtIndex(int index, {ShowHideEffect effect, int duration, EffectTiming effectTiming, ShowHideEffect hideEffect});
  Future<bool> showItem(Element item, {ShowHideEffect effect, int duration, EffectTiming effectTiming, ShowHideEffect hideEffect});
  // TODO: showItem with id?
}

abstract class ShowHideComponent {
  static const String _toggleEventName = 'toggle';

  static const EventStreamProvider<Event> toggleEvent = const EventStreamProvider<Event>(_toggleEventName);

  void show();

  void hide();

  void toggle();

  bool get isShown;

  void set isShown(bool value);

  Stream<Event> get onToggle;

  static void dispatchToggleEvent(Element element) {
    element.dispatchEvent(new Event(ShowHideComponent._toggleEventName));
  }
}
