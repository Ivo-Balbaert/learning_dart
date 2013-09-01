part of effects;

// TODO: maybe add a flag 'er somethin' to each animated element to detect
// ...conflicting animations? Maybe?

class ElementAnimation extends AnimationCore {
  static final _numberWithUnitRegExp = new RegExp('^([0-9\.]+)([a-zA-Z]+)\$');

  final Element element;

  final Map<String, Object> _targets = new Map<String, Object>();
  Map<String, Object> _initialValues;

  final String _property;
  final _target;

  ElementAnimation(this.element, this._property, this._target, {num duration: 400})
  : super(duration) {
    assert(_property != null);
  }

  void onStart() {
    assert(_initialValues == null);

    var target = _target;
    if(target is String) {
      target = _getPixels(target);
    }

    _targets[_property] = target;
    final style = element.getComputedStyle('');
    _populateInitialValues(style);
  }

  void onProgress(num progress) {
    assert(_initialValues != null);
    assert(isValidNumber(progress));
    _initialValues.forEach((k, v) {
      final num initial = v;
      final num target = _targets[k];
      final val = lerp(initial, target, progress);
      _setValue(k, val);
    });
  }

  void _populateInitialValues(CssStyleDeclaration value) {
    assert(value != null);
    assert(_initialValues == null);
    _initialValues = new Map<String, Object>();
    _targets.forEach((k,v) {
      _populateInitialValue(k, value.getPropertyValue(k));
    });
  }

  void _populateInitialValue(String property, String value) {
    final val = _getPixels(value);

    _initialValues[property] = val;
  }

  void _setValue(String property, num value) {
    final str = "${value.toInt().toString()}px";
    // TODO: Remove empty string as third param
    // Waiting on dartbug.com/10583
    element.style.setProperty(property, str, '');
  }

  double _getPixels(String value) {
    final match = _numberWithUnitRegExp.firstMatch(value);
    final valStr = match.group(1);
    final val = double.parse(valStr);
    final unitStr = match.group(2);

    // we're not supporting anything else...yet
    assert(unitStr == 'px');
    return val;
  }

}
