// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Datatypes holding information extracted by the analyzer and used by later
 * phases of the compiler.
 */
library web_ui.src.info;

import 'dart:collection' show SplayTreeMap, LinkedHashMap;

import 'package:analyzer_experimental/src/generated/ast.dart';
import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart';
import 'package:html5lib/dom.dart';
import 'package:source_maps/span.dart' show Span;

import 'dart_parser.dart' show DartCodeInfo;
import 'files.dart';
import 'messages.dart';
import 'summary.dart';
import 'utils.dart';

/**
 * Information for any library-like input. We consider each HTML file a library,
 * and each component declaration a library as well. Hence we use this as a base
 * class for both [FileInfo] and [ComponentInfo]. Both HTML files and components
 * can have .dart code provided by the user for top-level user scripts and
 * component-level behavior code. This code can either be inlined in the HTML
 * file or included in a script tag with the "src" attribute.
 */
abstract class LibraryInfo extends Hashable implements LibrarySummary {

  /** Whether there is any code associated with the page/component. */
  bool get codeAttached => inlinedCode != null || externalFile != null;

  /**
   * The actual inlined code. Use [userCode] if you want the code from this file
   * or from an external file.
   */
  DartCodeInfo inlinedCode;

  /**
   * If this library's code was loaded using a script tag (e.g. in a component),
   * [externalFile] has the path to such Dart file relative from the compiler's
   * base directory.
   */
  UrlInfo externalFile;

  /** Info asscociated with [externalFile], if any. */
  FileInfo externalCode;

  /**
   * The inverse of [externalCode]. If this .dart file was imported via a script
   * tag, this refers to the HTML file that imported it.
   */
  LibraryInfo htmlFile;

  /** File where the top-level code was defined. */
  UrlInfo get dartCodeUrl;

  /**
   * Name of the file that will hold any generated Dart code for this library
   * unit. Note this is initialized after parsing.
   */
  String outputFilename;

  /** Parsed cssSource. */
  List<StyleSheet> styleSheets = [];

  /** This is used in transforming Dart code to track modified files. */
  bool modified = false;

  /**
   * This is used in transforming Dart code to compute files that reference
   * [modified] files.
   */
  List<FileInfo> referencedBy = [];

  /**
   * Components used within this library unit. For [FileInfo] these are
   * components used directly in the page. For [ComponentInfo] these are
   * components used within their shadowed template.
   */
  final Map<ComponentSummary, bool> usedComponents =
      new LinkedHashMap<ComponentSummary, bool>();

  /**
   * The actual code, either inlined or from an external file, or `null` if none
   * was defined.
   */
  DartCodeInfo get userCode =>
      externalCode != null ? externalCode.inlinedCode : inlinedCode;
}

/** Information extracted at the file-level. */
class FileInfo extends LibraryInfo implements HtmlFileSummary {
  /** Relative path to this file from the compiler's base directory. */
  final UrlInfo inputUrl;

  /**
   * Whether this file should be treated as the entry point of the web app, i.e.
   * the file users navigate to in their browser. This will be true if this file
   * was passed in the command line to the dwc compiler, and the
   * `--components_only` flag was omitted.
   */
  final bool isEntryPoint;

  // TODO(terry): Ensure that that the libraryName is a valid identifier:
  //              a..z || A..Z || _ [a..z || A..Z || 0..9 || _]*
  String get libraryName =>
      path.basename(inputUrl.resolvedPath).replaceAll('.', '_');

  /** File where the top-level code was defined. */
  UrlInfo get dartCodeUrl => externalFile != null ? externalFile : inputUrl;

  /**
   * All custom element definitions in this file. This may contain duplicates.
   * Normally you should use [components] for lookup.
   */
  final List<ComponentInfo> declaredComponents = new List<ComponentInfo>();

  /**
   * All custom element definitions defined in this file or imported via
   *`<link rel='components'>` tag. Maps from the tag name to the component
   * information. This map is sorted by the tag name.
   */
  final Map<String, ComponentSummary> components =
      new SplayTreeMap<String, ComponentSummary>();

  /** Files imported with `<link rel="import">` */
  final List<UrlInfo> componentLinks = <UrlInfo>[];

  /** Files imported with `<link rel="stylesheet">` */
  final List<UrlInfo> styleSheetHrefs = <UrlInfo>[];

  /** Root is associated with the body info. */
  ElementInfo bodyInfo;

  FileInfo(this.inputUrl, [this.isEntryPoint = false]);

  /**
   * Query for an ElementInfo matching the provided [tag], starting from the
   * [bodyInfo].
   */
  ElementInfo query(String tag) => new _QueryInfo(tag).visit(bodyInfo);
}


/** Information about a web component definition declared locally. */
// TODO(sigmund): use a mixin to pull in ComponentSummary.
class ComponentInfo extends LibraryInfo implements ComponentSummary {
  /** The file that declares this component. */
  final FileInfo declaringFile;

  /** The component tag name, defined with the `name` attribute on `element`. */
  final String tagName;

  /**
   * The tag name that this component extends, defined with the `extends`
   * attribute on `element`.
   */
  final String extendsTag;

  /**
   * The component info associated with the [extendsTag] name, if any.
   * This will be `null` if the component extends a built-in HTML tag, or
   * if the analyzer has not run yet.
   */
  ComponentSummary extendsComponent;

  /** The Dart class containing the component's behavior. */
  String className;

  /** The Dart class declaration. */
  ClassDeclaration get classDeclaration => _classDeclaration;
  ClassDeclaration _classDeclaration;

  /** Component's ElementInfo at the element tag. */
  ElementInfo elemInfo;

  // TODO(terry): Remove once we stop mangling CSS selectors.
  /** CSS selectors scoped. */
  bool scoped = false;

  /** The declaring `<element>` tag. */
  final Node element;

  /** The component's `<template>` tag, if any. */
  final Node template;

  /** File where this component was defined. */
  UrlInfo get dartCodeUrl => externalFile != null
      ? externalFile : declaringFile.inputUrl;

  /**
   * True if [tagName] was defined by more than one component. If this happened
   * we will skip over the component.
   */
  bool hasConflict = false;

  ComponentInfo(this.element, this.declaringFile, this.tagName,
      this.extendsTag, this.template);

  /**
   * Gets the HTML tag extended by the base of the component hierarchy.
   * Equivalent to [extendsTag] if this inherits directly from an HTML element,
   * in other words, if [extendsComponent] is null.
   */
  String get baseExtendsTag =>
      extendsComponent == null ? extendsTag : extendsComponent.baseExtendsTag;

  Span get sourceSpan => element.sourceSpan;

  /**
   * Finds the declaring class, and initializes [className] and
   * [classDeclaration]. Also [userCode] is generated if there was no script.
   */
  void findClassDeclaration(Messages messages) {
    var constructor = element.attributes['constructor'];
    className = constructor != null ? constructor :
        toCamelCase(tagName, startUppercase: true);

    // If we don't have any code, generate a small class definition, and
    // pretend the user wrote it as inlined code.
    if (userCode == null) {
      var superclass = extendsComponent != null ? extendsComponent.className
          : 'autogenerated.WebComponent';
      inlinedCode = new DartCodeInfo(null, null, [],
          'class $className extends $superclass {\n}', null);
    }

    var code = userCode.code;
    _classDeclaration = userCode.findClass(className);
    if (_classDeclaration == null) {
      // Check for deprecated x-tags implied constructor.
      if (tagName.startsWith('x-') && constructor == null) {
        var oldCtor = toCamelCase(tagName.substring(2), startUppercase: true);
        _classDeclaration = userCode.findClass(oldCtor);
        if (_classDeclaration != null) {
          messages.warning('Implied constructor name for x-tags has changed to '
              '"$className". You should rename your class or add a '
              'constructor="$oldCtor" attribute to the element declaration. '
              'Also custom tags are not required to start with "x-" if their '
              'name has at least one dash.',
              element.sourceSpan);
          className = oldCtor;
        }
      }

      if (_classDeclaration == null) {
        messages.error('please provide a class definition '
            'for $className:\n $code', element.sourceSpan);
        return;
      }
    }
  }

  String toString() => '#<ComponentInfo $tagName '
      '${inlinedCode != null ? "inline" : "from ${dartCodeUrl.resolvedPath}"}>';
}

/** Base tree visitor for the Analyzer infos. */
class InfoVisitor {
  visit(info) {
    if (info == null) return;
    if (info is TemplateInfo) {
      return visitTemplateInfo(info);
    } else if (info is ElementInfo) {
      return visitElementInfo(info);
    } else if (info is TextInfo) {
      return visitTextInfo(info);
    } else if (info is ComponentInfo) {
      return visitComponentInfo(info);
    } else if (info is FileInfo) {
      return visitFileInfo(info);
    } else {
      throw new UnsupportedError('Unknown info type: $info');
    }
  }

  visitChildren(ElementInfo info) {
    for (var child in info.children) visit(child);
  }

  visitFileInfo(FileInfo info) {
    visit(info.bodyInfo);
    info.declaredComponents.forEach(visit);
  }

  visitTemplateInfo(TemplateInfo info) => visitElementInfo(info);

  visitElementInfo(ElementInfo info) => visitChildren(info);

  visitTextInfo(TextInfo info) {}

  visitComponentInfo(ComponentInfo info) => visit(info.elemInfo);
}

/** Common base class for [ElementInfo] and [TextInfo]. */
abstract class NodeInfo<T extends Node> {

  /** DOM node associated with this NodeInfo. */
  final T node;

  /** Info for the nearest enclosing element, iterator, or conditional. */
  final ElementInfo parent;

  /**
   * The name used to refer to this node in Dart code.
   * Depending on the context, this can be a variable or a field.
   */
  String identifier;

  /**
   * Whether the node represented by this info will be constructed from code.
   * If true, its identifier is initialized programatically, otherwise, its
   * identifier is initialized using a query.
   * The compiler currently creates in code text nodes with data-bindings,
   * siblings of text nodes with data-bindings, and immediate children of loops
   * and conditionals.
   */
  bool get createdInCode => parent != null && parent.childrenCreatedInCode;

  NodeInfo(this.node, this.parent, [this.identifier]) {
    if (parent != null) parent.children.add(this);
  }
}

/** Information extracted for each node in a template. */
class ElementInfo extends NodeInfo<Element> {
  // TODO(jmesserly): make childen work like DOM children collection, so that
  // adding/removing a node updates the parent pointer.
  final List<NodeInfo> children = [];

  /**
   * If this element is a web component instantiation (e.g. `<x-foo>`), this
   * will be set to information about the component, otherwise it will be null.
   */
  final ComponentSummary component;

  /** Whether any child of this node is created in code. */
  bool childrenCreatedInCode = false;

  /** Whether this node represents "body" or the shadow root of a component. */
  bool isRoot = false;

  /**
   * True if this element needs to be stored in a variable (or field) because
   * we'll access a descendant (child, grandchild, etc) needs a variable.
   * In that case, we'll access the descendant starting from this element using
   * a path. This will only be set if this element is [createdInCode].
   */
  bool descendantHasBinding = false;

  // Note: we're using sorted maps so items are enumerated in a consistent order
  // between runs, resulting in less "diff" in the generated code.
  // TODO(jmesserly): An alternative approach would be to use LinkedHashMap to
  // preserve the order of the input, but we'd need to be careful about our tree
  // traversal order.
  /** Collected information for attributes, if any. */
  final Map<String, AttributeInfo> attributes =
      new SplayTreeMap<String, AttributeInfo>();

  /** Collected information for UI events on the corresponding element. */
  final Map<String, List<EventInfo>> events =
      new SplayTreeMap<String, List<EventInfo>>();

  /**
   * Collected information about `data-value="name:value"` expressions.
   * Note: this feature is deprecated and should be removed after grace period.
   */
  final Map<String, String> values = new SplayTreeMap<String, String>();

  // TODO(jmesserly): we could keep this local to the analyzer.
  /** Attribute names to remove in cleanup phase. */
  final Set<String> removeAttributes = new Set<String>();

  /** Whether the template element has `iterate="... in ...". */
  bool get hasLoop => false;

  /** Whether the template element has an `if="..."` conditional. */
  bool get hasCondition => false;

  bool get isTemplateElement => false;

  /**
   * For a builtin HTML element this returns the [node.tagName], otherwise it
   * returns [component.baseExtendsTag]. This is useful when looking up which
   * DOM property this element supports.
   */
  String get baseTagName =>
      component != null ? component.baseExtendsTag : node.tagName;

  ElementInfo(Element node, ElementInfo parent, [this.component])
      : super(node, parent);

  String toString() => '#<ElementInfo '
      'identifier: $identifier, '
      'childrenCreatedInCode: $childrenCreatedInCode, '
      'component: $component, '
      'descendantHasBinding: $descendantHasBinding, '
      'hasLoop: $hasLoop, '
      'hasCondition: $hasCondition, '
      'attributes: $attributes, '
      'events: $events>';
}

/**
 * Information for a single text node created programatically. We create a
 * [TextInfo] for data bindings that occur in content nodes, and for each
 * text node that is created programatically in code. Note that the analyzer
 * splits HTML text nodes, so that each data-binding has its own node (and
 * [TextInfo]).
 */
class TextInfo extends NodeInfo<Text> {
  /** The data-bound Dart expression. */
  final BindingInfo binding;

  TextInfo(Text node, ElementInfo parent, [this.binding, String identifier])
      : super(node, parent, identifier);
}

/** Information extracted for each attribute in an element. */
class AttributeInfo {

  /**
   * Whether this is a `class` attribute. In which case more than one binding
   * is allowed (one per class).
   */
  final bool isClass;

  /**
   * Whether this is a 'data-style' attribute.
   */
  final bool isStyle;

  /** All bound values that would be monitored for changes. */
  final List<BindingInfo> bindings;

  /**
   * A two-way binding that needs a watcher. This is used in cases where we
   * don't have an event.
   */
  final bool customTwoWayBinding;

  /**
   * For a text attribute this contains the text content. This is used by most
   * attributes and represents the value that will be assigned to them. If this
   * has been assigned then [isText] will be true.
   *
   * The entries in this list correspond to the entries in [bindings], and this
   * will always have one more item than bindings. For example:
   *
   *     href="t0 {{b1}} t1 {{b2}} t2"
   *
   * Here textContent would be `["t0 ", " t1 ", " t2"]` and bindings would be
   * `["b1", "b2"]`.
   */
  final List<String> textContent;

  AttributeInfo(this.bindings, {this.isStyle: false, this.isClass: false,
      this.textContent, this.customTwoWayBinding: false}) {

    assert(isText || isClass || bindings.length == 1);
    assert(isText || bindings.length > 0);
    assert(!isText || textContent.length == bindings.length + 1);
    assert((isText ? 1 : 0) + (isClass ? 1 : 0) + (isStyle ? 1 : 0) <= 1);
  }

  /**
   * A value that will be monitored for changes. All attributes have a single
   * bound value unless [isClass] or [isText] is true.
   */
  String get boundValue => bindings[0].exp;

  /** Whether the binding should be evaluated only once. */
  bool get isBindingFinal => bindings[0].isFinal;

  /** True if this attribute binding expression should be assigned directly. */
  bool get isSimple => !isClass && !isStyle && !isText;

  /**
   * True if this attribute value should be concatenated as a string.
   * This is true whenever [textContent] is non-null.
   */
  bool get isText => textContent != null;

  String toString() => '#<AttributeInfo '
      'isClass: $isClass, values: ${bindings.join("")}>';
}

/** Information associated with a binding. */
class BindingInfo {
  /** The expression used in the binding. */
  final String exp;

  /** Whether the expression is treated as final (evaluated a single time). */
  final bool isFinal;

  BindingInfo(this.exp, this.isFinal);

  factory BindingInfo.fromText(text) {
    var pipeIndex = text.lastIndexOf('|');
    if (pipeIndex != -1 && text.substring(pipeIndex + 1).trim() == 'final') {
      return new BindingInfo(text.substring(0, pipeIndex).trim(), true);
    } else {
      return new BindingInfo(text, false);
    }
  }

  String toString() => '#<BindingInfo exp: $exp, isFinal: $isFinal>';
}

/** Information extracted for each declared event in an element. */
class EventInfo {
  /** Event stream name for attributes representing actions. */
  final String streamName;

  /** Action associated for event listener attributes. */
  final ActionDefinition action;

  /** Generated field name, if any, associated with this event. */
  String listenerField;

  EventInfo(this.streamName, this.action);

  String toString() => '#<EventInfo streamName: $streamName, action: $action>';
}

class TemplateInfo extends ElementInfo {
  /**
   * The expression that is used in `<template if="cond"> conditionals, or null
   * if this there is no `if="..."` attribute.
   */
  final String ifCondition;

  /**
   * If this is a `<template iterate="item in items">`, this is the variable
   * declared on loop iterations, e.g. `item`. This will be null if it is not
   * a `<template iterate="...">`.
   */
  final String loopVariable;

  /**
   * If this is a `<template iterate="item in items">`, this is the expression
   * to get the items to iterate over, e.g. `items`. This will be null if it is
   * not a `<template iterate="...">`.
   */
  final String loopItems;

  /**
   * If [hasLoop] is true, this indicates if the attribute was "repeat" instead
   * of "iterate".
   *
   * For template elements, the two are equivalent, but for template attributes
   * repeat causes that node to repeat in place, instead of iterating its
   * children.
   */
  final bool isRepeat;

  TemplateInfo(Node node, ElementInfo parent,
      {this.ifCondition, this.loopVariable, this.loopItems, this.isRepeat})
      : super(node, parent) {
    childrenCreatedInCode = hasCondition || hasLoop;
  }

  /**
   * True when [node] is a '<template>' tag. False when [node] is any other
   * element type and the template information is attached as an attribute.
   */
  bool get isTemplateElement => node.tagName == 'template';

  bool get hasCondition => ifCondition != null;

  bool get hasLoop => loopVariable != null;

  String toString() => '#<TemplateInfo ${super.toString()}'
      'ifCondition: $ifCondition, '
      'loopVariable: $ifCondition, '
      'loopItems: $ifCondition>';
}

/**
 * Specifies the action to take on a particular event. Some actions need to read
 * attributes from the DOM element that has the event listener (e.g. two way
 * bindings do this). [elementVarName] stores a reference to this element.
 * It is generated outside of the analyzer (in the emitter), so it is passed
 * here as an argument.
 */
typedef String ActionDefinition(String elementVarName);


/**
 * Find ElementInfo that associated with a particular DOM node.
 * Used by `ElementInfo.query(tagName)`.
 */
class _QueryInfo extends InfoVisitor {
  final String _tagName;

  _QueryInfo(this._tagName);

  visitElementInfo(ElementInfo info) {
    if (info.node.tagName == _tagName) {
      return info;
    }

    return super.visitElementInfo(info);
  }

  visitChildren(ElementInfo info) {
    for (var child in info.children) {
      var result = visit(child);
      if (result != null) return result;
    }
    return null;
  }
}

/**
 * Information extracted about a URL that refers to another file. This is
 * mainly introduced to be able to trace back where URLs come from when
 * reporting errors.
 */
class UrlInfo {
  /** Original url. */
  final String url;

  /** Path that the URL points to. */
  final String resolvedPath;

  /** Original source location where the URL was extracted from. */
  final Span sourceSpan;

  UrlInfo(this.url, this.resolvedPath, this.sourceSpan);

  /**
   * Resolve a path from an [url] found in a file located at [inputUrl].
   * Returns null for absolute [url]. Unless [ignoreAbsolute] is true, reports
   * an error message if the url is an absolute url.
   */
  static UrlInfo resolve(String url, UrlInfo inputUrl, Span span,
      String packageRoot, Messages messages, {bool ignoreAbsolute: false}) {

    var uri = Uri.parse(url);
    if (uri.host != '' || (uri.scheme != '' && uri.scheme != 'package')) {
      if (!ignoreAbsolute) {
        messages.error('absolute paths not allowed here: "$url"', span);
      }
      return null;
    }

    var target;
    if (url.startsWith('package:')) {
      target = path.join(packageRoot, url.substring(8));
    } else if (path.isAbsolute(url)) {
      if (!ignoreAbsolute) {
        messages.error('absolute paths not allowed here: "$url"', span);
      }
      return null;
    } else {
      target = path.join(path.dirname(inputUrl.resolvedPath), url);
      url = pathToUrl(path.normalize(path.join(
          path.dirname(inputUrl.url), url)));
    }
    target = path.normalize(target);

    return new UrlInfo(url, target, span);
  }

  bool operator ==(UrlInfo other) =>
      url == other.url && resolvedPath == other.resolvedPath;

  int get hashCode => resolvedPath.hashCode;

  String toString() => "#<UrlInfo url: $url, resolvedPath: $resolvedPath>";
}
