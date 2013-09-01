import 'dart:async';
import 'dart:html';
import 'package:web_ui/web_ui.dart';
import 'package:bot/bot.dart';
import 'package:widget/effects.dart';
import 'package:widget/widget.dart';

// TODO: option to enable/disable wrapping. Disable buttons if the end is hit...

/**
 * [Carousel] allows moving back and forth through a set of child elements.
 *
 * It is based on a [similar component](http://twitter.github.com/bootstrap/javascript.html#carousel)
 * in Bootstrap.
 *
 * [Carousel] leverages the [Swap] component to render the transition between items.
 */
class Carousel extends WebComponent {
  final ShowHideEffect _fromTheLeft = new SlideEffect(xStart: HorizontalAlignment.LEFT);
  final ShowHideEffect _fromTheRight = new SlideEffect(xStart: HorizontalAlignment.RIGHT);

  static const _duration = 2000;

  Future<bool> next() => _moveDelta(true);

  Future<bool> previous() => _moveDelta(false);

  SwapComponent get _swap =>
      this.query('[is=x-carousel] > .carousel > [is=x-swap]').xtag;

  Future<bool> _moveDelta(bool doNext) {
    final swap = _swap;
    assert(swap != null);
    if (swap.items.length == 0) {
      return new Future.value(false);
    }

    assert(doNext != null);
    final delta = doNext ? 1 : -1;

    ShowHideEffect showEffect, hideEffect;
    if (doNext) {
      showEffect = _fromTheRight;
      hideEffect = _fromTheLeft;
    } else {
      showEffect = _fromTheLeft;
      hideEffect = _fromTheRight;
    }

    final activeIndex = _swap.activeItemIndex;

    final newIndex = (activeIndex + delta) % _swap.items.length;

    return _swap.showItemAtIndex(newIndex, effect: showEffect,
        hideEffect: hideEffect, duration: _duration);
  }
}
