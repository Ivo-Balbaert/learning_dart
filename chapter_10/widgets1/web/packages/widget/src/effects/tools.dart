part of effects;

class Tools {
  static final Map<String, String> _elemDisplay = new Map<String, String>();

  static List<Element> getAncestors(Element source, [bool includeSelf = false]) {
    assert(source != null);
    List<Element> ancestors = new List<Element>();
    source = includeSelf ? source : source.parent;
    while(source != null) {
      ancestors.add(source);
      source = source.parent;
    }
    return ancestors;
  }

  static Size getSize(CssStyleDeclaration css) {
    assert(css != null);
    final width = _getPixelCount(css.width);
    final height = _getPixelCount(css.height);
    return new Size(width, height);
  }

  static Size getOuterSize(CssStyleDeclaration css) {
    assert(css != null);

    final outerWidth = getOuterWidth(css);
    final outerHeight = getOuterHeight(css);
    return new Size(outerWidth, outerHeight);
  }

  static double getOuterHeight(CssStyleDeclaration computedStyle) {
    final height = _getPixelCount(computedStyle.height);

    if(height == null) {
      return null;
    }

    final borderTop = _getPixelCount(computedStyle.borderTopWidth);
    final borderBottom = _getPixelCount(computedStyle.borderBottomWidth);
    final paddingTop = _getPixelCount(computedStyle.paddingTop);
    final paddingBottom = _getPixelCount(computedStyle.paddingBottom);

    return n$([borderTop, borderBottom, paddingTop, paddingBottom, height]).sum();
  }

  static double getOuterWidth(CssStyleDeclaration computedStyle) {
    final width = _getPixelCount(computedStyle.width);

    if(width == null) {
      return null;
    }

    final borderLeft = _getPixelCount(computedStyle.borderLeftWidth);
    final borderRight = _getPixelCount(computedStyle.borderRightWidth);
    final paddingLeft = _getPixelCount(computedStyle.paddingLeft);
    final paddingRight = _getPixelCount(computedStyle.paddingRight);

    return n$([borderLeft, borderRight, paddingLeft, paddingRight, width]).sum();
  }

  static double _getPixelCount(String cssDimension) {
    if(cssDimension == 'auto' || cssDimension.endsWith('%')) {
      return null;
    } else {
      assert(cssDimension.endsWith('px'));
      return double.parse(cssDimension.substring(0, cssDimension.length-2));
    }
  }

  // borrowing from here:
  // https://github.com/jquery/jquery/blob/054daa20afc0e2c84e66f450b155d0253a62aedb/src/css.js#L428
  // Try to determine the default display value of an element
  static String getDefaultDisplay(String nodeName ) {
    final storedValue = _elemDisplay[nodeName];
    if(storedValue != null) {
      return storedValue;
    } else {
      final defaultDisplay = _css_defaultDisplay(nodeName);

      assert(defaultDisplay != null);

      if(defaultDisplay == 'none' || defaultDisplay == '') {
        return _defaultDisplayHard(nodeName);
      } else {
        return defaultDisplay;
      }
    }
  }

  static String _css_defaultDisplay(String nodeName) {
    final doc = document;

    // skipping crazy iframe dance for now...
    return _actualDisplay(nodeName, document);
  }

  static String _defaultDisplayHard(String nodeName) {
    throw 'Not sure how to calculate display of: $nodeName';

    // TODO: can't make any progress here
    // IFrameElement.contentWindow is a WindowBase
    // which doesn't let me get to the doc.
    // *sigh*

    /*
    if(_iframe == null) {
      _iframe = new Element.tag('iframe')
      ..attributes['frameborder'] = '0'
      ..attributes['width'] = '0'
      ..attributes['height'] = '0'
      ..attributes['style'] = 'display: block !important';
    }

    document.body.children.add(_iframe);

    final frameDoc = _iframe.contentWindow;
    */
  }

  static String _actualDisplay(String name, HtmlDocument doc) {
    final elem = new Element.tag(name);
    doc.body.append(elem);

    final css = elem.getComputedStyle('');
    final value = css.display;
    elem.remove();
    return value;
  }

}
