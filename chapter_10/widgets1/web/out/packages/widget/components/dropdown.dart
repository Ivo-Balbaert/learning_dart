import 'dart:async';
import 'dart:html';
import 'package:bot/bot.dart';
import 'package:web_ui/web_ui.dart';
import 'package:widget/effects.dart';
import 'package:widget/widget.dart';

// TODO: esc and click outside to collapse
// https://github.com/kevmoo/widget.dart/issues/14

/**
 * [Dropdown] aligns closely with the model provided by the
 * [dropdown functionality](http://twitter.github.com/bootstrap/javascript.html#dropdowns)
 * in Bootstrap.
 *
 * [Dropdown] content is inferred from all child elements that have
 * class `dropdown-menu`. Bootstrap defines a CSS selector for `.dropdown-menu`
 * with an initial display of `none`.
 *
 * [Dropdown] listens for `click` events and toggles visibility of content if the
 * click target has attribute `data-toggle="dropdown"`.
 *
 * Bootstrap also defines a CSS selector which sets `display: block;` for elements
 * matching `.open > .dropdown-menu`. When [Dropdown] opens, the class `open` is
 * added to the inner element wrapping all content. Causing child elements with
 * class `dropdown-menu` to become visible.
 */
class Dropdown extends WebComponent implements ShowHideComponent {
  static final ShowHideEffect _effect = new FadeEffect();
  static const int _duration = 100;

  bool _isShown = false;

  bool get isShown => _isShown;

  void set isShown(bool value) {
    assert(value != null);
    if(value != _isShown) {

      if(value) {
        // before we set the local shown value, ensure
        // all of the other dropdowns are closed
        closeDropdowns();
      }

      _isShown = value;

      final action = _isShown ? ShowHideAction.SHOW : ShowHideAction.HIDE;

      final headerElement = this.query('[is=x-dropdown] > .dropdown');

      if(headerElement != null) {
        if(_isShown) {
          headerElement.classes.add('open');
        } else {
          headerElement.classes.remove('open');
        }
      }

      final contentDiv = this.query('[is=x-dropdown] > .dropdown-menu');
      if(contentDiv != null) {
        ShowHide.begin(action, contentDiv, effect: _effect);
      }
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

  static void closeDropdowns() {
    document.queryAll('[is=x-dropdown]')
      .where((e) => e.xtag is Dropdown)
      .map((e) => e.xtag as Dropdown)
      .forEach((dd) => dd.hide());
  }

  @protected
  void created() {
    this.onClick.listen(_onClick);
    this.onKeyDown.listen(_onKeyDown);
  }

  void _onKeyDown(KeyboardEvent e) {
    if(!e.defaultPrevented && e.keyCode == KeyCode.ESC) {
      this.hide();
      e.preventDefault();
    }
  }

  void _onClick(MouseEvent event) {
    if(!event.defaultPrevented && event.target is Element) {
      final Element target = event.target;
      if(target != null && target.dataset['toggle'] == 'dropdown') {
        toggle();
        event.preventDefault();
        target.focus();
      }
    }
  }
}
