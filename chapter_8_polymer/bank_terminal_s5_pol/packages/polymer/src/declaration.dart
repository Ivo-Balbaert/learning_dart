// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of polymer;

/**
 * **Deprecated**: use [Polymer.register] instead.
 *
 * Registers a [PolymerElement]. This is similar to [registerCustomElement]
 * but it is designed to work with the `<element>` element and adds additional
 * features.
 */
@deprecated
void registerPolymerElement(String localName, PolymerElement create()) {
  Polymer._registerClassMirror(localName, reflect(create()).type);
}

/**
 * **Warning**: this class is experiental and subject to change.
 *
 * The implementation for the `polymer-element` element.
 *
 * Normally you do not need to use this class directly, see [PolymerElement].
 */
class PolymerDeclaration extends CustomElement {
  // Fully ported from revision:
  // https://github.com/Polymer/polymer/blob/4dc481c11505991a7c43228d3797d28f21267779
  //
  //   src/declaration/attributes.js
  //   src/declaration/events.js
  //   src/declaration/polymer-element.js
  //   src/declaration/properties.js
  //   src/declaration/prototype.js (note: most code not needed in Dart)
  //   src/declaration/styles.js
  //
  // Not yet ported:
  //   src/declaration/path.js - blocked on HTMLImports.getDocumentUrl

  // TODO(jmesserly): these should be Type not ClassMirror. But we can't get
  // from ClassMirror to Type yet in dart2js, so we use ClassMirror for now.
  // See https://code.google.com/p/dart/issues/detail?id=12607
  ClassMirror _type;
  ClassMirror get type => _type;

  // TODO(jmesserly): this is a cache, because it's tricky in Dart to get from
  // ClassMirror -> Supertype.
  ClassMirror _supertype;
  ClassMirror get supertype => _supertype;

  // TODO(jmesserly): this is also a cache, since we can't store .element on
  // each level of the __proto__ like JS does.
  PolymerDeclaration _super;
  PolymerDeclaration get superDeclaration => _super;

  String _name;
  String get name => _name;

  /**
   * Map of publish properties. Can be a [VariableMirror] or a [MethodMirror]
   * representing a getter. If it is a getter, there will also be a setter.
   */
  Map<String, DeclarationMirror> _publish;

  /** The names of published properties for this polymer-element. */
  Iterable<String> get publishedProperties =>
      _publish != null ? _publish.keys : const [];

  /** Same as [_publish] but with lower case names. */
  Map<String, DeclarationMirror> _publishLC;

  Map<String, Symbol> _observe;

  Map<Symbol, Object> _instanceAttributes;

  List<Element> _sheets;
  List<Element> get sheets => _sheets;

  List<Element> _styles;
  List<Element> get styles => _styles;

  DocumentFragment get templateContent {
    final template = query('template');
    return template != null ? template.content : null;
  }

  /** Maps event names and their associated method in the element class. */
  final Map<String, String> _eventDelegates = {};

  /** Expected events per element node. */
  // TODO(sigmund): investigate whether we need more than 1 set of local events
  // per element (why does the js implementation stores 1 per template node?)
  Expando<Set<String>> _templateDelegates;

  void created() {
    super.created();

    // fetch the element name
    _name = attributes['name'];
    // install element definition, if ready
    registerWhenReady();
  }

  void registerWhenReady() {
    // if we have no prototype, wait
    if (waitingForType(name)) {
      return;
    }
    // fetch our extendee name
    var extendee = attributes['extends'];
    if (waitingForExtendee(extendee)) {
      //console.warn(name + ': waitingForExtendee:' + extendee);
      return;
    }
    // TODO(sjmiles): HTMLImports polyfill awareness:
    // elements in the main document are likely to parse
    // in advance of elements in imports because the
    // polyfill parser is simulated
    // therefore, wait for imports loaded before
    // finalizing elements in the main document
    // TODO(jmesserly): Polymer.dart waits for HTMLImportsLoaded, so I've
    // removed "whenImportsLoaded" for now. Restore the workaround if needed.
    _register(extendee);
  }

  void _register(extendee) {
    //console.group('registering', name);
    register(name, extendee);
    //console.groupEnd();
    // subclasses may now register themselves
    _notifySuper(name);
  }

  bool waitingForType(String name) {
    if (_getRegisteredType(name) != null) return false;

    // then wait for a prototype
    _waitType[name] = this;
    // if explicitly marked as 'noscript'
    if (attributes.containsKey('noscript')) {
      // TODO(sorvell): CustomElements polyfill awareness:
      // noscript elements should upgrade in logical order
      // script injection ensures this under native custom elements;
      // under imports + ce polyfills, scripts run before upgrades.
      // dependencies should be ready at upgrade time so register
      // prototype at this time.
      // TODO(jmesserly): I'm not sure how to port this; since script
      // injection doesn't work for Dart, we'll just call Polymer.register
      // here and hope for the best.
      Polymer.register(name);
    }
    return true;
  }

  bool waitingForExtendee(String extendee) {
    // if extending a custom element...
    if (extendee != null && extendee.indexOf('-') >= 0) {
      // wait for the extendee to be _registered first
      if (!_isRegistered(extendee)) {
        _waitSuper.putIfAbsent(extendee, () => []).add(this);
        return true;
      }
    }
    return false;
  }

  void register(String name, String extendee) {
    // build prototype combining extendee, Polymer base, and named api
    buildType(name, extendee);

    // back reference declaration element
    // TODO(sjmiles): replace `element` with `elementElement` or `declaration`
    _declarations[_type] = this;

    // more declarative features
    desugar();

    // TODO(sorvell): install a helper method this.resolvePath to aid in
    // setting resource paths. e.g.
    // this.$.image.src = this.resolvePath('images/foo.png')
    // Potentially remove when spec bug is addressed.
    // https://www.w3.org/Bugs/Public/show_bug.cgi?id=21407
    // TODO(jmesserly): resolvePath not ported, see first comment in this class.

    // under ShadowDOMPolyfill, transforms to approximate missing CSS features
    _shimShadowDomStyling(templateContent, name);

    // register our custom element
    registerType(name);

    // NOTE: skip in Dart because we don't have mutable global scope.
    // reference constructor in a global named by 'constructor' attribute
    // publishConstructor();
  }

  /**
   * Gets the Dart type registered for this name, and sets up declarative
   * features. Fills in the [type] and [supertype] fields.
   *
   * *Note*: unlike the JavaScript version, we do not have to metaprogram the
   * prototype, which simplifies this method.
   */
  void buildType(String name, String extendee) {
    // get our custom type
    _type = _getRegisteredType(name);

    // get basal prototype
    _supertype = _getRegisteredType(extendee);
    if (supertype != null) _super = _getDeclaration(supertype);

    // transcribe `attributes` declarations onto own prototype's `publish`
    publishAttributes(type, _super);

    publishProperties(type);

    inferObservers(type);

    // Skip the rest in Dart:
    // chain various meta-data objects to inherited versions
    // chain custom api to inherited
    // build side-chained lists to optimize iterations
    // inherit publishing meta-data
    //this.inheritAttributesObjects(prototype);
    //this.inheritDelegates(prototype);
    // x-platform fixups
  }

  /** Implement various declarative features. */
  void desugar() {
    // compile list of attributes to copy to instances
    accumulateInstanceAttributes();
    // parse on-* delegates declared on `this` element
    parseHostEvents();
    // parse on-* delegates declared in templates
    parseLocalEvents();
    // install external stylesheets as if they are inline
    installSheets();
    // TODO(jmesserly): this feels unnatrual in Dart. Since we have convenient
    // lazy static initialization, can we get by without it?
    var registered = type.methods[const Symbol('registerCallback')];
    if (registered != null && registered.isStatic &&
        registered.isRegularMethod) {
      type.invoke(const Symbol('registerCallback'), [this]);
    }

  }

  void registerType(String name) {
    // TODO(jmesserly): document.register
    registerCustomElement(name, () =>
        type.newInstance(const Symbol(''), const []).reflectee);
  }

  void publishAttributes(ClassMirror type, PolymerDeclaration superDecl) {
    // get properties to publish
    if (superDecl != null && superDecl._publish != null) {
      _publish = new Map.from(superDecl._publish);
    }
    _publish = _getProperties(type, _publish, (x) => x is PublishedProperty);

    // merge names from 'attributes' attribute
    var attrs = attributes['attributes'];
    if (attrs != null) {
      // names='a b c' or names='a,b,c'
      // record each name for publishing
      for (var attr in attrs.split(attrs.contains(',') ? ',' : ' ')) {
        // remove excess ws
        attr = attr.trim();

        // do not override explicit entries
        if (_publish != null && _publish.containsKey(attr)) continue;

        var property = new Symbol(attr);
        var mirror = type.variables[property];
        if (mirror == null) {
          mirror = type.getters[property];
          if (mirror != null && !_hasSetter(type, mirror)) mirror = null;
        }
        if (mirror == null) {
          window.console.warn('property for attribute $attr of polymer-element '
              'name=$name not found.');
          continue;
        }
        if (_publish == null) _publish = {};
        _publish[attr] = mirror;
      }
    }

    // NOTE: the following is not possible in Dart; fields must be declared.
    // install 'attributes' as properties on the prototype,
    // but don't override
  }

  void accumulateInstanceAttributes() {
    // inherit instance attributes
    _instanceAttributes = new Map<Symbol, Object>();
    if (_super != null) _instanceAttributes.addAll(_super._instanceAttributes);

    // merge attributes from element
    attributes.forEach((name, value) {
      if (isInstanceAttribute(name)) {
        _instanceAttributes[new Symbol(name)] = value;
      }
    });
  }

  static bool isInstanceAttribute(name) {
    // do not clone these attributes onto instances
    final blackList = const {
        'name': 1, 'extends': 1, 'constructor': 1, 'noscript': 1,
        'attributes': 1};

    return !blackList.containsKey(name) && !name.startsWith('on-');
  }

  /** Extracts events from the element tag attributes. */
  void parseHostEvents() {
    addAttributeDelegates(_eventDelegates);
  }

  void addAttributeDelegates(Map<String, String> delegates) {
    attributes.forEach((name, value) {
      if (_hasEventPrefix(name)) {
        delegates[_removeEventPrefix(name)] = value;
      }
    });
  }

  /** Extracts events under the element's <template>. */
  void parseLocalEvents() {
    for (var t in queryAll('template')) {
      final events = new Set<String>();
      // acquire delegates from entire subtree at t
      accumulateTemplatedEvents(t, events);
      if (events.isNotEmpty) {
        // store delegate information directly on template
        if (_templateDelegates == null) {
          _templateDelegates = new Expando<Set<String>>();
        }
        _templateDelegates[t] = events;
      }
    }
  }

  void accumulateTemplatedEvents(Element node, Set<String> events) {
    if (node.localName == 'template' && node.content != null) {
      accumulateChildEvents(node.content, events);
    }
  }

  void accumulateChildEvents(node, Set<String> events) {
    assert(node is Element || node is DocumentFragment);
    for (var n in node.children) {
      accumulateEvents(n, events);
    }
  }

  void accumulateEvents(Element node, Set<String> events) {
    accumulateAttributeEvents(node, events);
    accumulateChildEvents(node, events);
    accumulateTemplatedEvents(node, events);
  }

  void accumulateAttributeEvents(Element node, Set<String> events) {
    for (var name in node.attributes.keys) {
      if (_hasEventPrefix(name)) {
        accumulateEvent(_removeEventPrefix(name), events);
      }
    }
  }

  void accumulateEvent(String name, Set<String> events) {
    var translated = _eventTranslations[name];
    events.add(translated != null ? translated : name);
  }

  String urlToPath(String url) {
    if (url == null) return '';
    return (url.split('/')..removeLast()..add('')).join('/');
  }

  /**
   * Install external stylesheets loaded in <element> elements into the
   * element's template.
   */
  void installSheets() {
    cacheSheets();
    cacheStyles();
    installLocalSheets();
    installGlobalStyles();
  }

  void cacheSheets() {
    _sheets = findNodes(_SHEET_SELECTOR);
    for (var s in sheets) s.remove();
  }

  void cacheStyles() {
    _styles = findNodes('$_STYLE_SELECTOR[$_SCOPE_ATTR]');
    for (var s in styles) s.remove();
  }

  /**
   * Takes external stylesheets loaded in an `<element>` element and moves
   * their content into a style element inside the `<element>`'s template.
   * The sheet is then removed from the `<element>`. This is done only so
   * that if the element is loaded in the main document, the sheet does
   * not become active.
   * Note, ignores sheets with the attribute 'polymer-scope'.
   */
  void installLocalSheets() {
    var sheets = this.sheets.where(
        (s) => !s.attributes.containsKey(_SCOPE_ATTR));
    var content = this.templateContent;
    if (content != null) {
      var cssText = new StringBuffer();
      for (var sheet in sheets) {
        cssText..write(_cssTextFromSheet(sheet))..write('\n');
      }
      if (cssText.length > 0) {
        content.insertBefore(
            new StyleElement()..text = '$cssText',
            content.firstChild);
      }
    }
  }

  List<Element> findNodes(String selector, [bool matcher(Element e)]) {
    var nodes = this.queryAll(selector).toList();
    var content = this.templateContent;
    if (content != null) {
      nodes = nodes..addAll(content.queryAll(selector));
    }
    if (matcher != null) return nodes.where(matcher).toList();
    return nodes;
  }

  /**
   * Promotes external stylesheets and style elements with the attribute
   * polymer-scope='global' into global scope.
   * This is particularly useful for defining @keyframe rules which
   * currently do not function in scoped or shadow style elements.
   * (See wkb.ug/72462)
   */
  // TODO(sorvell): remove when wkb.ug/72462 is addressed.
  void installGlobalStyles() {
    var style = styleForScope(_STYLE_GLOBAL_SCOPE);
    _applyStyleToScope(style, document.head);
  }

  String cssTextForScope(String scopeDescriptor) {
    var cssText = new StringBuffer();
    // handle stylesheets
    var selector = '[$_SCOPE_ATTR=$scopeDescriptor]';
    matcher(s) => s.matches(selector);

    for (var sheet in sheets.where(matcher)) {
      cssText..write(_cssTextFromSheet(sheet))..write('\n\n');
    }
    // handle cached style elements
    for (var style in styles.where(matcher)) {
      cssText..write(style.textContent)..write('\n\n');
    }
    return cssText.toString();
  }

  StyleElement styleForScope(String scopeDescriptor) {
    var cssText = cssTextForScope(scopeDescriptor);
    return cssTextToScopeStyle(cssText, scopeDescriptor);
  }

  StyleElement cssTextToScopeStyle(String cssText, String scopeDescriptor) {
    if (cssText == '') return null;

    return new StyleElement()
        ..text = cssText
        ..attributes[_STYLE_SCOPE_ATTRIBUTE] = '$name-$scopeDescriptor';
  }

  /**
   * fetch a list of all observable properties names in our inheritance chain
   * above Polymer.
   */
  // TODO(sjmiles): perf: reflection is slow, relatively speaking
  // If an element may take 6us to create, getCustomPropertyNames might
  // cost 1.6us more.
  void inferObservers(ClassMirror type) {
    for (var method in type.methods.values) {
      if (method.isStatic || !method.isRegularMethod) continue;

      String name = MirrorSystem.getName(method.simpleName);
      if (name.endsWith('Changed')) {
        if (_observe == null) _observe = {};
        name = name.substring(0, name.length - 7);
        _observe[name] = method.simpleName;
      }
    }
  }

  void publishProperties(ClassMirror type) {
    // Dart note: _publish was already populated by publishAttributes
    if (_publish != null) _publishLC = _lowerCaseMap(_publish);
  }

  Map<String, dynamic> _lowerCaseMap(Map<String, dynamic> properties) {
    final map = new Map<String, dynamic>();
    properties.forEach((name, value) {
      map[name.toLowerCase()] = value;
    });
    return map;
  }
}

/// maps tag names to prototypes
final Map _typesByName = new Map<String, ClassMirror>();

ClassMirror _getRegisteredType(String name) => _typesByName[name];

/// elements waiting for prototype, by name
final Map _waitType = new Map<String, PolymerDeclaration>();

void _notifyType(String name) {
  var waiting = _waitType.remove(name);
  if (waiting != null) waiting.registerWhenReady();
}

/// elements waiting for super, by name
final Map _waitSuper = new Map<String, List<PolymerDeclaration>>();

void _notifySuper(String name) {
  _registered.add(name);
  var waiting = _waitSuper.remove(name);
  if (waiting != null) {
    for (var w in waiting) {
      w.registerWhenReady();
    }
  }
}

/// track document.register'ed tag names
final Set _registered = new Set<String>();

bool _isRegistered(name) => _registered.contains(name);

final Map _declarations = new Map<ClassMirror, PolymerDeclaration>();

PolymerDeclaration _getDeclaration(ClassMirror type) => _declarations[type];

final _objectType = reflectClass(Object);

Map _getProperties(ClassMirror type, Map props, bool matches(metadata)) {
  for (var field in type.variables.values) {
    if (field.isFinal || field.isStatic || field.isPrivate) continue;

    for (var meta in field.metadata) {
      if (matches(meta.reflectee)) {
        if (props == null) props = {};
        props[MirrorSystem.getName(field.simpleName)] = field;
        break;
      }
    }
  }

  for (var getter in type.getters.values) {
    if (getter.isStatic || getter.isPrivate) continue;

    for (var meta in getter.metadata) {
      if (matches(meta.reflectee)) {
        if (_hasSetter(type, getter)) {
          if (props == null) props = {};
          props[MirrorSystem.getName(getter.simpleName)] = getter;
        }
        break;
      }
    }
  }

  return props;
}

bool _hasSetter(ClassMirror type, MethodMirror getter) {
  var setterName = new Symbol('${MirrorSystem.getName(getter.simpleName)}=');
  return type.setters.containsKey(setterName);
}

bool _inDartHtml(ClassMirror type) =>
    type.owner.simpleName == const Symbol('dart.dom.html');


/** Attribute prefix used for declarative event handlers. */
const _EVENT_PREFIX = 'on-';

/** Whether an attribute declares an event. */
bool _hasEventPrefix(String attr) => attr.startsWith(_EVENT_PREFIX);

String _removeEventPrefix(String name) => name.substring(_EVENT_PREFIX.length);

/**
 * Using Polymer's platform/src/ShadowCSS.js passing the style tag's content.
 */
void _shimShadowDomStyling(DocumentFragment template, String localName) {
  if (js.context == null || template == null) return;

  var platform = js.context['Platform'];
  if (platform == null) return;

  var style = template.query('style');
  if (style == null) return;

  var shadowCss = platform['ShadowCSS'];
  if (shadowCss == null) return;

  // TODO(terry): Remove calls to shimShadowDOMStyling2 and replace with
  //              shimShadowDOMStyling when we support unwrapping dart:html
  //              Element to a JS DOM node.
  var shimShadowDOMStyling2 = shadowCss['shimShadowDOMStyling2'];
  if (shimShadowDOMStyling2 == null) return;

  var scopedCSS = shimShadowDOMStyling2.apply(shadowCss,
      [style.text, localName]);

  // TODO(terry): Remove when shimShadowDOMStyling is called we don't need to
  //              replace original CSS with scoped CSS shimShadowDOMStyling
  //              does that.
  style.text = scopedCSS;
}

const _STYLE_SELECTOR = 'style';
const _SHEET_SELECTOR = '[rel=stylesheet]';
const _STYLE_GLOBAL_SCOPE = 'global';
const _SCOPE_ATTR = 'polymer-scope';
const _STYLE_SCOPE_ATTRIBUTE = 'element';

void _applyStyleToScope(StyleElement style, Node scope) {
  if (style == null) return;

  // TODO(sorvell): necessary for IE
  // see https://connect.microsoft.com/IE/feedback/details/790212/
  // cloning-a-style-element-and-adding-to-document-produces
  // -unexpected-result#details
  // var clone = style.cloneNode(true);
  var clone = new StyleElement()..text = style.text;

  var attr = style.attributes[_STYLE_SCOPE_ATTRIBUTE];
  if (attr != null) {
    clone.attributes[_STYLE_SCOPE_ATTRIBUTE] = attr;
  }

  scope.append(clone);
}

String _cssTextFromSheet(Element sheet) {
  if (sheet == null || js.context == null) return '';

  // TODO(jmesserly): this is a hacky way to communcate with HTMLImports...

  // Remove rel=stylesheet, href to keep this inert.
  var href = sheet.attributes.remove('href');
  var rel = sheet.attributes.remove('rel');
  document.body.append(sheet);
  String resource;
  try {
    resource = js.context['document']['body']['lastChild']['__resource'];
  } finally {
    sheet.remove();
    if (href != null) sheet.attributes['href'] = href;
    if (rel != null) sheet.attributes['rel'] = rel;
  }
  return resource != null ? resource : '';
}

const _OBSERVE_SUFFIX = 'Changed';

// TODO(jmesserly): is this list complete?
final _eventTranslations = const {
  // TODO(jmesserly): these three Polymer.js translations won't work in Dart,
  // because we strip the webkit prefix (below). Reconcile.
  'webkitanimationstart': 'webkitAnimationStart',
  'webkitanimationend': 'webkitAnimationEnd',
  'webkittransitionend': 'webkitTransitionEnd',

  'domfocusout': 'DOMFocusOut',
  'domfocusin': 'DOMFocusIn',

  // TODO(jmesserly): Dart specific renames. Reconcile with Polymer.js
  'animationend': 'webkitAnimationEnd',
  'animationiteration': 'webkitAnimationIteration',
  'animationstart': 'webkitAnimationStart',
  'doubleclick': 'dblclick',
  'fullscreenchange': 'webkitfullscreenchange',
  'fullscreenerror': 'webkitfullscreenerror',
  'keyadded': 'webkitkeyadded',
  'keyerror': 'webkitkeyerror',
  'keymessage': 'webkitkeymessage',
  'needkey': 'webkitneedkey',
  'speechchange': 'webkitSpeechChange',
};

final _reverseEventTranslations = () {
  final map = new Map<String, String>();
  _eventTranslations.forEach((onName, eventType) {
    map[eventType] = onName;
  });
  return map;
}();

// Dart note: we need this function because we have additional renames JS does
// not have. The JS renames are simply case differences, whereas we have ones
// like doubleclick -> dblclick and stripping the webkit prefix.
String _eventNameFromType(String eventType) {
  final result = _reverseEventTranslations[eventType];
  return result != null ? result : eventType;
}
