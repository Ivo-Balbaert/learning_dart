part of effects;

class ShowHideState extends _Enum {
  static const ShowHideState SHOWN = const ShowHideState._internal('shown');
  static const ShowHideState HIDDEN = const ShowHideState._internal('hidden');
  static const ShowHideState SHOWING = const ShowHideState._internal('showing');
  static const ShowHideState HIDING = const ShowHideState._internal('hidding');

  static ShowHideState byName(String name) {
    return $([SHOWN, HIDDEN, SHOWING, HIDING]).singleWhere((shs) => shs.cssName == name);
  }

  const ShowHideState._internal(String name) : super(name);

  bool get isFinished => this == HIDDEN || this == SHOWN;

  bool get isShow => this == SHOWN || this == SHOWING;
}
