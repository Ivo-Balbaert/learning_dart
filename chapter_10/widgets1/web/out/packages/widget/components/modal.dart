import 'dart:async';
import 'dart:html';
import 'package:web_ui/web_ui.dart';
import 'package:bot/bot.dart';
import 'package:widget/effects.dart';
import 'package:widget/widget.dart';

// TODO: ESC to close: https://github.com/kevmoo/widget.dart/issues/17

/**
 * When added to a page, [Modal] is hidden. It can be displayed by calling the `show` method.
 *
 * Similar to [Alert], elements with the attribute `data-dismiss="modal"` will close [Modal] when clicked.
 *
 * Content within [Modal] is placed in a div with class `modal` so related styles from Bootstrap are applied.
 *
 * The [Modal] component leverages the [ModalManager] effect.
 */
class Modal extends WebComponent implements ShowHideComponent {
  bool _isShown = false;

  bool get isShown => _isShown;

  void set isShown(bool value) {
    assert(value != null);
    if(value != _isShown) {
      _isShown = value;

      final modal = _getModalElement();
      if(modal != null) {
        final effect = new ScaleEffect();

        if(_isShown) {
          ModalManager.show(modal, effect: effect, backdropClickHandler: _onBackdropClicked);
        } else {
          ModalManager.hide(modal, effect: effect);
        }
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

  @protected
  void created() {
    this.onClick.listen(_onClick);
  }

  @protected
  void inserted() {
    final modal = _getModalElement();
    if(modal != null && !isShown) {
      ModalManager.hide(modal);
    }
  }

  Element _getModalElement() => this.query('[is=x-modal] > .modal');

  void _onClick(MouseEvent event) {
    if(!event.defaultPrevented) {
      final Element target = event.target as Element;
      if(target != null && target.dataset['dismiss'] == 'modal') {
        hide();
      }
    }
  }

  void _onBackdropClicked() {
    // TODO: ignoring some edge cases here
    // like what if this element has been removed from the tree before the backdrop is clicked
    // ...etc
    hide();
  }
}
