import 'dart:async';
import 'dart:html';
import 'package:bot/bot.dart';
import 'package:web_ui/web_ui.dart';
import 'package:widget/effects.dart';
import 'package:widget/widget.dart';

/**
 * [Collapse] uses a content model similar to [collapse functionality](http://twitter.github.com/bootstrap/javascript.html#collapse) in Bootstrap.
 *
 * The header element for [Collapse] is a child element with class `accordion-heading`.
 *
 * The rest of the children are rendered as content.
 *
 * [Collapse] listens for `click` events and toggles visibility of content if the
 * click target has attribute `data-toggle="collapse"`.
 */
class Collapse extends WebComponent implements ShowHideComponent {
  static const String _collapseDivSelector = '.collapse-body-x';
  static final ShowHideEffect _effect = new ShrinkEffect();

  bool _isShown = true;

  bool get isShown => _isShown;

  void set isShown(bool value) {
    assert(value != null);
    if(value != _isShown) {
      _isShown = value;
      _updateElements();

      ShowHideComponent.dispatchToggleEvent(this);
    }
  }

  Stream<Event> get onToggle => ShowHideComponent.toggleEvent.forTarget(this);

  void hide() {
    isShown = false;
  }

  void show() {
    isShown = true;
  }

  void toggle() {
    isShown = !isShown;
  }

  @protected
  void created() {
    this.onClick.listen(_onClick);
  }

  @protected
  void inserted() {
    _updateElements(true);
  }

  void _onClick(MouseEvent e) {
    if(!e.defaultPrevented) {
      final clickElement = e.target as Element;

      if(clickElement != null && clickElement.dataset['toggle'] == 'collapse') {
        toggle();
        e.preventDefault();
      }
    }
  }

  void _updateElements([bool skipAnimation = false]) {
    final collapseDiv = this.query(_collapseDivSelector);
    if(collapseDiv != null) {
      final action = _isShown ? ShowHideAction.SHOW : ShowHideAction.HIDE;
      final effect = skipAnimation ? null : _effect;
      ShowHide.begin(action, collapseDiv, effect: effect);
    }
  }
}
