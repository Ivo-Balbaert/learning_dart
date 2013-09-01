part of effects;

// At some point, we will want to support non-CSS3 timings at which point the
// each of the pre-defined CSS timings will include their corresponding logic
// for any timing engine.
//
// In the mean time, we will expose code up the API to be a bit future proof,
// while only supporting the CSS timings w/ CSS transitions
class EffectTiming {
  static final EffectTiming linear = new CssEffectTiming._internal('linear');
  static final EffectTiming ease = new CssEffectTiming._internal('ease');
  static final EffectTiming easeIn = new CssEffectTiming._internal('ease-in');
  static final EffectTiming easeInOut = new CssEffectTiming._internal('ease-in-out');
  static final EffectTiming easeOut = new CssEffectTiming._internal('ease-out');

  static EffectTiming get defaultTiming => ease;

}

class CssEffectTiming extends EffectTiming {
  final String cssName;

  CssEffectTiming._internal(this.cssName);

  static String _getCssValue(EffectTiming timing) {
    assert(timing != null);
    if(timing is CssEffectTiming) {
      final CssEffectTiming ccsET = timing;
      return ccsET.cssName;
    } else {
      return '';
    }
  }
}
