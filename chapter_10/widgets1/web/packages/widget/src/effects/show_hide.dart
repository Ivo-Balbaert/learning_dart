part of effects;

class ShowHideAction extends _Enum {
  static const ShowHideAction SHOW = const ShowHideAction._internal("show");
  static const ShowHideAction HIDE = const ShowHideAction._internal('hide');
  static const ShowHideAction TOGGLE = const ShowHideAction._internal('toggle');

  const ShowHideAction._internal(String name) : super(name);
}

class ShowHideResult extends _Enum {
  static const ShowHideResult ANIMATED = const ShowHideResult._internal("animated");
  static const ShowHideResult NOOP = const ShowHideResult._internal("no-op");
  static const ShowHideResult IMMEDIATE = const ShowHideResult._internal("immediate");
  static const ShowHideResult CANCELED = const ShowHideResult._internal("canceled");

  const ShowHideResult._internal(String name) : super(name);

  bool get isSuccess => this != CANCELED;
}

/**
 * [ShowHide] is an effect inspired by the [basic effects in jQuery](http://api.jquery.com/category/effects/basics/).
 * Provide an element and an action--show, hide, toggle--and the element's display will change accordingly.
 * Custom effects, duration, and easing values can also be provided.
 *
 * At the moment, all of the provided effects leverage CSS3 transitions. Creating new effects is easy.
 *
 * [ShowHide] is used by [Collapse] and [DropDown] to animate their content.
 * It is also used by [Swapper].
 */
class ShowHide {
  static const int _defaultDuration = 400;
  static final Map<String, String> _defaultDisplays = new Map<String, String>();
  static final Expando<_ShowHideValues> _values = new Expando<_ShowHideValues>('_ShowHideValues');

  static ShowHideState getState(Element element) {
    assert(element != null);
    return _populateState(element);
  }

  static Future<ShowHideResult> show(Element element,
      {ShowHideEffect effect, int duration, EffectTiming effectTiming}) {
    return begin(ShowHideAction.SHOW, element, effect: effect, duration: duration, effectTiming: effectTiming);
  }

  static Future<ShowHideResult> hide(Element element,
      {ShowHideEffect effect, int duration, EffectTiming effectTiming}) {
    return begin(ShowHideAction.HIDE, element, effect: effect, duration: duration, effectTiming: effectTiming);
  }

  static Future<ShowHideResult> toggle(Element element,
      {ShowHideEffect effect, int duration, EffectTiming effectTiming}) {
    return begin(ShowHideAction.TOGGLE, element, effect: effect, duration: duration, effectTiming: effectTiming);
  }

  static Future<ShowHideResult> begin(ShowHideAction action, Element element,
      {ShowHideEffect effect, int duration, EffectTiming effectTiming}) {
    assert(action != null);
    assert(element != null);

    final oldState = getState(element);
    final doShow = _getToggleState(action, oldState);

    return _requestEffect(doShow, element, duration, effect, effectTiming);
  }

  static ShowHideState _populateState(Element element) {
    final currentValues = _values[element];

    if(currentValues != null) {
      return currentValues.currentState;
    }

    final computedStyle = element.getComputedStyle('');
    final tagDefaultDisplay = Tools.getDefaultDisplay(element.tagName);

    _defaultDisplays.putIfAbsent(element.tagName, () => tagDefaultDisplay);

    final localDisplay = element.style.display;
    final computedDisplay = computedStyle.display;
    final inferredState = computedDisplay == 'none' ? ShowHideState.HIDDEN : ShowHideState.SHOWN;
    final size = Tools.getSize(computedStyle);

    _values[element] = new _ShowHideValues(computedDisplay, localDisplay, inferredState);
    return inferredState;
  }

  static bool _getToggleState(ShowHideAction action, ShowHideState state) {
    switch(action) {
      case ShowHideAction.SHOW:
        return true;
      case ShowHideAction.HIDE:
        return false;
      case ShowHideAction.TOGGLE:
        switch(state) {
          case ShowHideState.HIDDEN:
          case ShowHideState.HIDING:
            return true;
          case ShowHideState.SHOWING:
          case ShowHideState.SHOWN:
            return false;
          default:
            throw new DetailedArgumentError('state', 'Value of $state is not supported');
        }

        // DARTBUG: http://code.google.com/p/dart/issues/detail?id=6563
        // dart2js knows this break is not needed, but the analyzer hasn't
        // caught up yet
        break;
      default:
        throw new DetailedArgumentError('action', 'Value of $action is not supported');
    }
  }

  static Future<ShowHideResult> _requestEffect(bool doShow, Element element, int desiredDuration,
      ShowHideEffect effect, EffectTiming effectTiming) {

    //
    // clean up possible null or invalid values
    //
    if(desiredDuration == null) {
      desiredDuration = _defaultDuration;
    } else if(desiredDuration < 0) {
      desiredDuration = 0;
    }

    effect = ShowHideEffect._orDefault(effect);

    if(effectTiming == null) {
      effectTiming = EffectTiming.defaultTiming;
    }

    //
    // do the transform
    //
    if(doShow) {
      return _requestShow(element, desiredDuration, effect, effectTiming);
    } else {
      return _requestHide(element, desiredDuration, effect, effectTiming);
    }
  }

  static Future<ShowHideResult> _requestShow(Element element, int desiredDuration,
      ShowHideEffect effect, EffectTiming effectTiming) {
    assert(element != null);
    assert(desiredDuration != null);
    assert(effect != null);
    assert(effectTiming != null);
    final values = _values[element];

    switch(values.currentState) {
      case ShowHideState.SHOWING:
        // no op - let the current animation finish
        assert(_AnimatingValues.isAnimating(element));
        return new Future.value(ShowHideResult.NOOP);
      case ShowHideState.SHOWN:
        // no op. If shown leave it.
        assert(!_AnimatingValues.isAnimating(element));
        return new Future.value(ShowHideResult.NOOP);
      case ShowHideState.HIDING:
        _AnimatingValues.cancelAnimation(element);
        break;
      case ShowHideState.HIDDEN:
        // handeled below with a fall-through
        break;
      default:
        throw new DetailedArgumentError('oldState', 'the provided value ${values.currentState} is not supported');
    }

    assert(!_AnimatingValues.isAnimating(element));
    _finishShow(element);
    final durationMS = effect.startShow(element, desiredDuration, effectTiming);
    if(durationMS > 0) {

      // _finishShow sets the currentState to shown, but we know better since we're animating
      assert(values.currentState == ShowHideState.SHOWN);
      values.currentState = ShowHideState.SHOWING;
      return _AnimatingValues.scheduleCleanup(durationMS, element, effect.clearAnimation, _finishShow);
    } else {
      assert(values.currentState == ShowHideState.SHOWN);
      return new Future.value(ShowHideResult.IMMEDIATE);
    }
  }

  static void _finishShow(Element element) {
    final values = _values[element];
    assert(!_AnimatingValues.isAnimating(element));
    element.style.display = _getShowDisplayValue(element);
    values.currentState = ShowHideState.SHOWN;
  }

  static Future<ShowHideResult> _requestHide(Element element, int desiredDuration,
      ShowHideEffect effect, EffectTiming effectTiming) {
    assert(element != null);
    assert(desiredDuration != null);
    assert(effect != null);
    assert(effectTiming != null);
    final values = _values[element];

    switch(values.currentState) {
      case ShowHideState.HIDING:
        // no op - let the current animation finish
        assert(_AnimatingValues.isAnimating(element));
        return new Future.value(ShowHideResult.NOOP);
      case ShowHideState.HIDDEN:
        // it's possible we're here because the inferred calculated value is 'none'
        // this hard-wires the local display value to 'none'...just to be clear
        _finishHide(element);
        return new Future.value(ShowHideResult.NOOP);
      case ShowHideState.SHOWING:
        _AnimatingValues.cancelAnimation(element);
        break;
      case ShowHideState.SHOWN:
        // handeled below with a fall-through
        break;
      default:
        throw new DetailedArgumentError('oldState', 'the provided value ${values.currentState} is not supported');
    }

    assert(!_AnimatingValues.isAnimating(element));
    final durationMS = effect.startHide(element, desiredDuration, effectTiming);
    if(durationMS > 0) {
      _values[element].currentState = ShowHideState.HIDING;
      return _AnimatingValues.scheduleCleanup(durationMS, element, effect.clearAnimation, _finishHide);
    } else {
      _finishHide(element);
      assert(values.currentState == ShowHideState.HIDDEN);
      return new Future.value(ShowHideResult.IMMEDIATE);
    }
  }

  static void _finishHide(Element element) {
    final values = _values[element];
    assert(!_AnimatingValues.isAnimating(element));
    element.style.display = 'none';
    values.currentState = ShowHideState.HIDDEN;
  }

  static String _getShowDisplayValue(Element element) {
    final values = _values[element];

    if(values.initialComputedDisplay == 'none') {
      // if the element was initially invisible, it's tough to know "why"
      // even if the element has a local display value of 'none' it still
      // might have inherited it from a style sheet
      // so we play say and set the local value to the tag default
      final tagDefault = _defaultDisplays[element.tagName];
      assert(tagDefault != null);
      return tagDefault;
    } else {
      if(values.initialLocalDisplay == '' || values.initialLocalDisplay == 'inherit') {
        // it was originally visible and the local value was empty
        // so returning the local value to '' should ensure it's visible
        return values.initialLocalDisplay;
      } else {
        // it was initially visible, cool
        return values.initialComputedDisplay;
      }
    }
  }
}

class _ShowHideValues {
  final String initialComputedDisplay;
  final String initialLocalDisplay;
  ShowHideState currentState;

  _ShowHideValues(this.initialComputedDisplay, this.initialLocalDisplay, this.currentState);
}

class _AnimatingValues {
  static final Expando<_AnimatingValues> _aniValues = new Expando<_AnimatingValues>('_AnimatingValues');

  final Element _element;
  final Action1<Element> _cleanupAction;
  final Action1<Element> _finishFunc;
  final Completer<ShowHideResult> _completer = new Completer<ShowHideResult>();

  Timer _timer;

  _AnimatingValues._internal(this._element, this._cleanupAction, this._finishFunc) {
    assert(_aniValues[_element] == null);
    _aniValues[_element] = this;
  }

  Future<ShowHideResult> _start(int durationMS) {
    assert(durationMS > 0);
    assert(_timer == null);
    _timer = new Timer(new Duration(milliseconds: durationMS), _complete);
    return _completer.future;
  }

  void _cancel() {
    assert(_timer != null);
    _timer.cancel();
    _cleanup();
    _completer.complete(ShowHideResult.CANCELED);
  }

  void _complete() {
    _cleanup();
    _finishFunc(_element);
    _completer.complete(ShowHideResult.ANIMATED);
  }

  void _cleanup() {
    assert(_aniValues[_element] != null);
    _cleanupAction(_element);
    _aniValues[_element] = null;
  }

  static bool isAnimating(Element element) {
    final values = _aniValues[element];
    return values != null;
  }

  static void cancelAnimation(Element element) {
    final values = _aniValues[element];
    assert(values != null);
    values._cancel();
  }

  static Future<ShowHideResult> scheduleCleanup(int durationMS, Element element,
                              Action1<Element> cleanupAction,
                              Action1<Element> finishAction) {

    final value = new _AnimatingValues._internal(element, cleanupAction, finishAction);
    return value._start(durationMS);
  }
}
