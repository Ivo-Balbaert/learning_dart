part of effects;

class FadeEffect extends Css3TransitionEffect {
  FadeEffect() : super('opacity', '0', '1');
}

// TODO: orientation
class ShrinkEffect extends Css3TransitionEffect {
  ShrinkEffect() : super('max-height', '0', '500px', {'overflow': 'hidden'});

  @protected
  @override
  String overrideStartEndValues(bool showValue, String property, String originalValue) {
    if(property == 'max-height' && showValue) {
      // TODO: this is a horrible hack. Need to figure out a way to get the original size
      //       but the perf loss for calculating cached size is too great.
      final size = new Size(500, 500);
      return '${size.height.toInt()}px';
    } else {
      return originalValue;
    }
  }
}

class ScaleEffect extends Css3TransitionEffect {

  factory ScaleEffect({Orientation orientation, HorizontalAlignment xOffset, VerticalAlignment yOffset}) {
    String hideValue;
    switch(orientation) {
      case Orientation.VERTICAL:
        hideValue = 'scale(1, 0)';
        break;
      case Orientation.HORIZONTAL:
        hideValue = 'scale(0, 1)';
        break;
      default:
        hideValue = 'scale(0, 0)';
        break;
    }

    if(xOffset == null) {
      xOffset = HorizontalAlignment.CENTER;
    }
    final xoValue = xOffset.name;

    if(yOffset == null) {
      yOffset = VerticalAlignment.MIDDLE;
    }
    final yoValue = (yOffset == VerticalAlignment.MIDDLE) ? 'center' : yOffset.name;

    final map = {'-webkit-transform-origin' : '$xoValue $yoValue'};

    return new ScaleEffect._internal(hideValue, map);
  }

  ScaleEffect._internal(String hideValue, Map<String, String> values) :
    super('-webkit-transform', hideValue, 'scale(1, 1)', values);
}

class SpinEffect extends Css3TransitionEffect {
  SpinEffect() : super('-webkit-transform', 'perspective(600px) rotateX(90deg)', 'perspective(600px) rotateX(0deg)');
}

class DoorEffect extends Css3TransitionEffect {
  DoorEffect() : super('-webkit-transform', 'perspective(1000px) rotateY(90deg)', 'perspective(1000px) rotateY(0deg)',
      {'-webkit-transform-origin': '0% 50%'} );
}

class SlideEffect extends Css3TransitionEffect {
  factory SlideEffect({HorizontalAlignment xStart, VerticalAlignment yStart}) {
    String xComponent;
    switch(xStart) {
      case HorizontalAlignment.LEFT:
        xComponent = '-100%';
        break;
      case HorizontalAlignment.RIGHT:
        xComponent = '100%';
        break;
      case HorizontalAlignment.CENTER:
      default:
        xComponent = '0';
        break;
    }

    String yComponent;
    switch(yStart) {
      case VerticalAlignment.TOP:
        yComponent = '-100%';
        break;
      case VerticalAlignment.BOTTOM:
        yComponent = '100%';
        break;
      case VerticalAlignment.MIDDLE:
      default:
        yComponent = '0';
        break;
    }

    return new SlideEffect._internal('translate($xComponent, $yComponent)');
  }

  SlideEffect._internal(String hideValue) :
    super('-webkit-transform', hideValue, 'translate(0)');
}
