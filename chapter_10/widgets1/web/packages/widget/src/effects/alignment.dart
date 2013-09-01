part of effects;

// TODO: move the corresponding classes in bot_retained to bot core and
// use them here, too

class Orientation extends _Enum {
  static const Orientation HORIZONTAL =
      const Orientation._internal('horizontal');

  static const Orientation VERTICAL =
      const Orientation._internal('vertical');

  const Orientation._internal(String name) : super(name);
}

class HorizontalAlignment extends _Enum {
  static const HorizontalAlignment LEFT =
      const HorizontalAlignment._internal('left');

  static const HorizontalAlignment RIGHT =
      const HorizontalAlignment._internal('right');

  static const HorizontalAlignment CENTER =
      const HorizontalAlignment._internal('center');

  const HorizontalAlignment._internal(String name) : super(name);
}

class VerticalAlignment extends _Enum {
  static const VerticalAlignment TOP =
      const VerticalAlignment._internal('top');

  static const VerticalAlignment BOTTOM =
      const VerticalAlignment._internal('bottom');

  static const VerticalAlignment MIDDLE =
      const VerticalAlignment._internal('middle');

  const VerticalAlignment._internal(String name) : super(name);
}
