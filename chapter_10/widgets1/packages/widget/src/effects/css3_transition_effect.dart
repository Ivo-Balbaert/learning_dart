part of effects;

class Css3TransitionEffect extends ShowHideEffect {
  static const List<String> _reservedProperties = const ['transitionProperty', 'transitionDuration'];
  final String _property;
  final String _hideValue;
  final String _showValue;
  final Map<String, String> _animatingOverrides;

  Css3TransitionEffect(this._property, this._hideValue, this._showValue, [Map<String, String> animatingOverrides]) : _animatingOverrides = animatingOverrides == null ? new Map<String, String>() : new Map<String, String>.from(animatingOverrides) {
    assert(!_animatingOverrides.containsKey(_property));
    assert(!_reservedProperties.contains(_property));
    assert(_reservedProperties.every((p) => !_animatingOverrides.containsKey(p)));
  }

  @protected
  @override
  int startShow(Element element, int desiredDuration, EffectTiming timing) {
    return _startAnimation(true, element, desiredDuration, _hideValue, _showValue, timing);
  }

  @protected
  @override
  int startHide(Element element, int desiredDuration, EffectTiming timing) {
    return _startAnimation(false, element, desiredDuration, _showValue, _hideValue, timing);
  }

  @protected
  // Use this to modify a provided override given the calculated size of the element
  // Note that if the size is not calculatable, this method is not called and the
  // original value is used
  String overrideStartEndValues(bool showValue, String property, String originalValue) {
    return originalValue;
  }

  @override
  void clearAnimation(Element element) {
    final restoreValues = _css3TransitionEffectValues.cleanup(element);

    element.style.transitionTimingFunction = '';
    element.style.transitionProperty = '';
    element.style.transitionDuration = '';

    restoreValues.forEach((p, v) {
      // TODO: Remove empty string as third param
      // Waiting on dartbug.com/10583
      element.style.setProperty(p, v, '');
    });
  }

  int _startAnimation(bool doingShow, Element element, int desiredDuration,
                      String startValue, String endValue, EffectTiming timing) {
    assert(desiredDuration > 0);
    assert(timing != null);

    final localPropsToKeep = [_property];
    localPropsToKeep.addAll(_animatingOverrides.keys);

    final localValues = _recordProperties(element, localPropsToKeep);

    _animatingOverrides.forEach((p, v) {
      // TODO: Remove empty string as third param
      // Waiting on dartbug.com/10583
      element.style.setProperty(p, v, '');
    });

    startValue = overrideStartEndValues(!doingShow, _property, startValue);
    endValue = overrideStartEndValues(doingShow, _property, endValue);

    // TODO: Remove empty string as third param
    // Waiting on dartbug.com/10583
    element.style.setProperty(_property, startValue, '');
    _css3TransitionEffectValues.delayStart(element, localValues,
        () => _setShowValue(element, endValue, desiredDuration, timing));
    return desiredDuration;
  }

  void _setShowValue(Element element, String value, int desiredDuration, EffectTiming timing) {
    final cssTimingValue = CssEffectTiming._getCssValue(timing);

    element.style.transitionTimingFunction = cssTimingValue;
    element.style.transitionProperty = _property;
    element.style.transitionDuration = '${desiredDuration}ms';
    // TODO: Remove empty string as third param
    // Waiting on dartbug.com/10583
    element.style.setProperty(_property, value, '');
  }

  static Map<String, String> _recordProperties(Element element, Iterable<String> properties) {
    final map = new Map<String, String>();

    for(final p in properties) {
      assert(!map.containsKey(p));
      map[p] = element.style.getPropertyValue(p);
    }

    return map;
  }
}

class _css3TransitionEffectValues {
  static final Expando<_css3TransitionEffectValues> _values =
      new Expando<_css3TransitionEffectValues>("_css3TransitionEffectValues");

  final Element element;
  final Map<String, String> originalValues;
  Timer timer;

  _css3TransitionEffectValues(this.element, this.originalValues);

  Map<String, String> _cleanup() {
    if(timer != null) {
      timer.cancel();
      timer = null;
    }

    return originalValues;
  }

  static void delayStart(Element element, Map<String, String> originalValues, Action0 action) {
    assert(_values[element] == null);

    final value = _values[element] = new _css3TransitionEffectValues(element, originalValues);

    value.timer = new Timer(const Duration(milliseconds: 1), () {
      assert(value.timer != null);
      value.timer = null;
      action();
    });

  }

  static Map<String, String> cleanup(Element element) {
    final value = _values[element];
    assert(value != null);
    _values[element] = null;
    return value._cleanup();
  }
}


