part of effects;

class ShowHideEffect {

  const ShowHideEffect();

  @protected
  // NOTE: size can be null
  int startShow(Element element, int desiredDuration, EffectTiming timing) {
    return 0;
  }

  @protected
  // NOTE: size can be null
  int startHide(Element element, int desiredDuration, EffectTiming timing) {
    return 0;
  }

  @protected
  void clearAnimation(Element element) {
    // no op here
  }

  static ShowHideEffect _orDefault(ShowHideEffect effect) {
    return effect == null ? const ShowHideEffect() : effect;
  }
}
