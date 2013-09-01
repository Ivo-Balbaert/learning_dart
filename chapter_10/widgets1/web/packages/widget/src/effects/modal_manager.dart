part of effects;

/**
 * [ModalManager] is inspired by the [modal helper](http://twitter.github.com/bootstrap/javascript.html#modals) in Bootstrap.
 *
 * It has two static methods `show` and `hide` that both take the same parameters as corresponding methods in [ShowHide].
 *
 * [ModalManager] controls the display of the provided element while also creating a dark backdrop on the page.
 * Any element used should have a fixed position, a z-index greater than 1040, and an initial display of none.
 */
class ModalManager {
  static const _backdropClass = 'modal-backdrop-x';
  static const _backdropStyle = '''display: none; position: fixed; top: 0; right: 0; bottom: 0; left: 0; z-index: 1040; background-color: rgba(0,0,0,0.8);''';

  static Future show(Element element,
                   {ShowHideEffect effect, int duration, EffectTiming effectTiming, Action0 backdropClickHandler}) {

    final backDropElement = _getBackdrop(element.document, true);

    if(backdropClickHandler != null) {
      backDropElement.onClick.listen((args) => backdropClickHandler());
    }

    final showElement = ShowHide.show(element, effect: effect, duration: duration, effectTiming: effectTiming);
    final showBackdrop = ShowHide.show(backDropElement, effect: new FadeEffect());

    return Future.wait([showElement, showBackdrop]);
  }

  static Future hide(Element element,
                   {ShowHideEffect effect, int duration, EffectTiming effectTiming}) {
    assert(element != null);

    final backDropElement = _getBackdrop(element.document, false);

    final futures = [ShowHide.hide(element, effect: effect, duration: duration, effectTiming: effectTiming)];

    if(backDropElement != null) {
      futures.add(ShowHide.hide(backDropElement, effect: new FadeEffect()));
    }

    return Future.wait(futures)
        .catchError((err) {
          print(err);
        }, test: (v) => false)
        ..whenComplete(() => _clearOutBackdrop(element.document));
  }

  static void _clearOutBackdrop(HtmlDocument doc) {
    final backdrop = _getBackdrop(doc, false);
    if(backdrop != null) {
      backdrop.remove();
    }
  }

  static Element _getBackdrop(HtmlDocument parentDocument, bool addIfMissing) {
    assert(parentDocument != null);


    Element element = parentDocument.body.query('.$_backdropClass');
    if(element == null && addIfMissing) {
      element = new DivElement()
        ..classes.add(_backdropClass)
        ..attributes['style'] = _backdropStyle;
      parentDocument.body.children.add(element);
    }

    return element;
  }
}
