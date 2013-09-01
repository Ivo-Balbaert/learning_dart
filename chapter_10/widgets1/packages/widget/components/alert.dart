import 'dart:async';
import 'dart:html';
import 'package:web_ui/web_ui.dart';
import 'package:bot/bot.dart';
import 'package:widget/effects.dart';
import 'package:widget/widget.dart';

/**
 * [Alert] follows the same convention as [its inspiration](http://twitter.github.com/bootstrap/javascript.html#alerts) in Bootstrap.
 *
 * Clicking on a nested element with the attribute `data-dismiss='alert'` will cause [Alert] to close.
 */
class Alert extends WebComponent implements ShowHideComponent {

  bool _isShown = true;

  bool get isShown => _isShown;

  void set isShown(bool value) {
    assert(value != null);
    if(value != _isShown) {
      _isShown = value;
      final action = _isShown ? ShowHideAction.SHOW : ShowHideAction.HIDE;
      ShowHide.begin(action, this, effect: new ScaleEffect());

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

  void _onClick(MouseEvent event) {
    if(!event.defaultPrevented) {
      final Element target = event.target as Element;
      if(target != null && target.dataset['dismiss'] == 'alert') {
        hide();
      }
    }
  }
}
