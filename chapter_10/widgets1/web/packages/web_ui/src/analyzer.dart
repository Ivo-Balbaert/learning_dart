// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Part of the template compilation that concerns with extracting information
 * from the HTML parse tree.
 */
library analyzer;

import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart' show StyleSheet, treeToDebugString, Visitor, Expressions, VarDefinition;
import 'package:html5lib/dom.dart';
import 'package:html5lib/dom_parsing.dart';
import 'package:source_maps/span.dart' hide SourceFile;

import 'dart_parser.dart';
import 'files.dart';
import 'html_css_fixup.dart';
import 'html5_utils.dart';
import 'info.dart';
import 'messages.dart';
import 'summary.dart';
import 'utils.dart';

/**
 * Finds custom elements in this file and the list of referenced files with
 * component declarations. This is the first pass of analysis on a file.
 *
 * Adds emitted error/warning messages to [messages], if [messages] is
 * supplied.
 */
FileInfo analyzeDefinitions(UrlInfo inputUrl,
    Document document, String packageRoot,
    Messages messages, {bool isEntryPoint: false}) {
  var result = new FileInfo(inputUrl, isEntryPoint);
  var loader = new _ElementLoader(result, packageRoot, messages);
  loader.visit(document);
  return result;
}

/**
 * Extract relevant information from [source] and it's children.
 * Used for testing.
 *
 * Adds emitted error/warning messages to [messages], if [messages] is
 * supplied.
 */
FileInfo analyzeNodeForTesting(Node source, Messages messages,
    {String filepath: 'mock_testing_file.html'}) {
  var result = new FileInfo(new UrlInfo(filepath, filepath, null));
  new _Analyzer(result, new IntIterator(), new Map(), messages).visit(source);
  return result;
}

/**
 *  Extract relevant information from all files found from the root document.
 *
 *  Adds emitted error/warning messages to [messages], if [messages] is
 *  supplied.
 */
void analyzeFile(SourceFile file, Map<String, FileInfo> info,
                 Iterator<int> uniqueIds, Map<String, String> pseudoElements,
                 Messages messages) {
  var fileInfo = info[file.path];
  var analyzer = new _Analyzer(fileInfo, uniqueIds, pseudoElements, messages);
  analyzer._normalize(fileInfo, info);
  analyzer.visit(file.document);
}


/** A visitor that walks the HTML to extract all the relevant information. */
class _Analyzer extends TreeVisitor {
  final FileInfo _fileInfo;
  LibraryInfo _currentInfo;
  ElementInfo _parent;
  Iterator<int> _uniqueIds;
  Map<String, String> _pseudoElements;
  Messages _messages;

  /**
   * Whether to keep indentation spaces. Break lines and indentation spaces
   * within templates are preserved in HTML. When users specify the attribute
   * 'indentation="remove"' on a template tag, we'll trim those indentation
   * spaces that occur within that tag and its decendants. If any decendant
   * specifies 'indentation="preserve"', then we'll switch back to the normal
   * behavior.
   */
  bool _keepIndentationSpaces = true;

  /**
   * Adds emitted error/warning messages to [_messages].
   * [_messages] must not be null.
   * Adds pseudo attribute value found on any HTML tag to [_pseudoElements].
   * [_pseudoElements] must not be null.
   */
  _Analyzer(this._fileInfo, this._uniqueIds, this._pseudoElements,
      this._messages) {
    assert(this._pseudoElements != null);
    assert(this._messages != null);
    _currentInfo = _fileInfo;
  }

  void visitElement(Element node) {
    var info = null;
    if (node.tagName == 'script') {
      // We already extracted script tags in previous phase.
      return;
    }

    if (node.tagName == 'template'
        || node.attributes.containsKey('template')
        || node.attributes.containsKey('if')
        || node.attributes.containsKey('instantiate')
        || node.attributes.containsKey('iterate')
        || node.attributes.containsKey('repeat')) {
      // template tags, conditionals and iteration are handled specially.
      info = _createTemplateInfo(node);
    }

    // TODO(jmesserly): it would be nice not to create infos for text or
    // elements that don't need data binding. Ideally, we would visit our
    // child nodes and get their infos, and if any of them need data binding,
    // we create an ElementInfo for ourselves and return it, otherwise we just
    // return null.
    if (info == null) {
      // <element> tags are tracked in the file's declared components, so they
      // don't need a parent.
      var parent = node.tagName == 'element' ? null : _parent;
      info = _createElementInfo(node, parent);
    }

    visitElementInfo(info);

    if (_parent == null) {
      _fileInfo.bodyInfo = info;
    }
  }

  void visitElementInfo(ElementInfo info) {
    var node = info.node;

    if (node.tagName == 'body' || (_currentInfo is ComponentInfo
          && (_currentInfo as ComponentInfo).template == node)) {
      info.isRoot = true;
      info.identifier = '__root';
    }

    var lastInfo = _currentInfo;
    if (node.tagName == 'element') {
      // If element is invalid _ElementLoader already reported an error, but
      // we skip the body of the element here.
      var name = node.attributes['name'];
      if (name == null) return;

      ComponentInfo component = _fileInfo.components[name];
      if (component == null) return;

      // Associate ElementInfo of the <element> tag with its component.
      component.elemInfo = info;

      _analyzeComponent(component);

      _currentInfo = component;
    }

    node.attributes.forEach((k, v) => visitAttribute(info, k, v));

    var savedParent = _parent;
    _parent = info;
    var keepSpaces = _keepIndentationSpaces;
    if (node.tagName == 'template' &&
        node.attributes.containsKey('indentation')) {
      var value = node.attributes['indentation'];
      if (value != 'remove' && value != 'preserve') {
        _messages.warning(
            "Invalid value for 'indentation' ($value). By default we preserve "
            "the indentation. Valid values are either 'remove' or 'preserve'.",
            node.sourceSpan);
      }
      _keepIndentationSpaces = value != 'remove';
    }

    // Invoke super to visit children.
    super.visitElement(node);

    _keepIndentationSpaces = keepSpaces;
    _currentInfo = lastInfo;
    _parent = savedParent;

    if (_needsIdentifier(info)) {
      _ensureParentHasVariable(info);
      if (info.identifier == null) {
        _uniqueIds.moveNext();
        info.identifier = toCamelCase('__e-${_uniqueIds.current}');
      }
    }
  }

  /**
   * If this [info] is not created in code, ensure that whichever parent element
   * is created in code has been marked appropriately, so the parent is stored
   * in a variable/field and we can access this element from it.
   */
  static void _ensureParentHasVariable(ElementInfo info) {
    if (info.isRoot || info.createdInCode) return;

    for (var p = info.parent; p != null; p = p.parent) {
      if (p.createdInCode) {
        p.descendantHasBinding = true;
        return;
      }
    }
  }

  /**
   * Whether code generators need to create a field to store a reference to this
   * element. This is typically true whenever we need to access the element
   * (e.g. to add event listeners, update values on data-bound watchers, etc).
   */
  static bool _needsIdentifier(ElementInfo info) {
    if (info.isRoot) return false;

    return info.childrenCreatedInCode || info.descendantHasBinding ||
        info.component != null || info.attributes.length > 0 ||
        info.values.length > 0 || info.events.length > 0;
  }

  void _analyzeComponent(ComponentInfo component) {
    component.extendsComponent = _fileInfo.components[component.extendsTag];
    if (component.extendsComponent == null &&
        isCustomTag(component.extendsTag)) {
      _messages.warning(
          'custom element with tag name ${component.extendsTag} not found.',
          component.element.sourceSpan);
    }

    // Now that the component's code has been loaded, we can validate that the
    // class exists.
    component.findClassDeclaration(_messages);
  }

  ElementInfo _createElementInfo(Element node, ElementInfo parent) {
    var component = _bindCustomElement(node);
    if (component != null && node.attributes['is'] == null) {
      // We need to ensure the correct DOM element is created in the tree.
      // Until we get document.register and the browser's HTML parser can do
      // the right thing for us, we switch to the is="tag-name" form.

      // TODO(jmesserly): it's a shame we mutate the tree here instead of
      // html_cleaner, but that would require mutating the node field of info,
      // and risk references to the original node leaking into other objects,
      // which seems worse.
      var newNode = new Element.tag(component.baseExtendsTag);
      newNode.attributes['is'] = node.tagName;
      node.attributes.forEach((k, v) {
        newNode.attributes[k] = v;
      });
      newNode.nodes.addAll(node.nodes);
      node.replaceWith(newNode);
      node = newNode;
    }

    return new ElementInfo(node, parent, component);
  }

  ComponentSummary _bindCustomElement(Element node) {
    // <fancy-button>
    var component = _fileInfo.components[node.tagName];
    if (component == null) {
      // TODO(jmesserly): warn for unknown element tags?

      // <button is="fancy-button">
      var componentName = node.attributes['is'];
      if (componentName != null) {
        component = _fileInfo.components[componentName];
      } else if (isCustomTag(node.tagName)) {
        componentName = node.tagName;
      }
      if (component == null && componentName != null) {
        _messages.warning(
            'custom element with tag name $componentName not found.',
            node.sourceSpan);
      }
    }
    if (component != null && !component.hasConflict) {
      _currentInfo.usedComponents[component] = true;
      return component;
    }
    return null;
  }

  TemplateInfo _createTemplateInfo(Element node) {
    if (node.tagName != 'template' &&
        !node.attributes.containsKey('template')) {
      _messages.warning('template attribute is required when using if, '
          'instantiate, repeat, or iterate attributes.',
          node.sourceSpan);
    }

    var instantiate = node.attributes['instantiate'];
    var condition = node.attributes['if'];
    if (instantiate != null) {
      if (instantiate.startsWith('if ')) {
        if (condition != null) {
          _messages.warning(
              'another condition was already defined on this element.',
              node.sourceSpan);
        } else {
          condition = instantiate.substring(3);
        }
      }
    }

    // TODO(jmesserly): deprecate iterate.
    var iterate = node.attributes['iterate'];
    var repeat = node.attributes['repeat'];
    if (repeat == null) {
      repeat = iterate;
    } else if (iterate != null) {
      _messages.warning('template cannot have both iterate and repeat. '
          'iterate attribute will be ignored.', node.sourceSpan);
      iterate = null;
    }

    // Note: we issue warnings instead of errors because the spirit of HTML and
    // Dart is to be forgiving.
    if (condition != null && repeat != null) {
      _messages.warning('template cannot have both iteration and conditional '
          'attributes', node.sourceSpan);
      return null;
    }

    if (node.parent != null && node.parent.tagName == 'element' &&
        (condition != null || repeat != null)) {

      // TODO(jmesserly): would be cool if we could just refactor this, or offer
      // a quick fix in the Editor.
      var example = new Element.html('<element><template><template>');
      node.parent.attributes.forEach((k, v) { example.attributes[k] = v; });
      var nestedTemplate = example.nodes.first.nodes.first;
      node.attributes.forEach((k, v) { nestedTemplate.attributes[k] = v; });

      _messages.warning('the <template> of a custom element does not support '
          '"if", "iterate" or "repeat". However, you can create another '
          'template node that is a child node, for example:\n'
          '${example.outerHtml}',
          node.parent.sourceSpan);
      return null;
    }

    if (condition != null) {
      var result = new TemplateInfo(node, _parent, ifCondition: condition);
      result.removeAttributes.add('if');
      result.removeAttributes.add('instantiate');
      if (node.tagName == 'template') {
        return node.nodes.length > 0 ? result : null;
      }

      _createTemplateAttributePlaceholder(node, result);
      return result;

    } else if (repeat != null) {
      var match = new RegExp(r"(.*) in (.*)").firstMatch(repeat);
      if (match == null) {
        _messages.warning('template iterate/repeat must be of the form: '
            'repeat="variable in list", where "variable" is your variable name '
            'and "list" is the list of items.',
            node.sourceSpan);
        return null;
      }

      if (node.nodes.length == 0) return null;
      var result = new TemplateInfo(node, _parent, loopVariable: match[1],
          loopItems: match[2], isRepeat: iterate == null);
      result.removeAttributes.add('iterate');
      result.removeAttributes.add('repeat');
      if (node.tagName == 'template') {
        return result;
      }

      if (!result.isRepeat) {
        result.removeAttributes.add('template');
        // TODO(jmesserly): deprecate this? I think you want "template repeat"
        // most of the time, but "template iterate" seems useful sometimes.
        // (Native <template> element parsing would make both obsolete, though.)
        return result;
      }

      _createTemplateAttributePlaceholder(node, result);
      return result;
    }

    return null;
  }

  // TODO(jmesserly): if and repeat in attributes require injecting a
  // placeholder node, and a real node which is a clone. We should
  // consider a design where we show/hide the node instead (with care
  // taken not to evaluate hidden bindings). That is more along the lines
  // of AngularJS, and would have a cleaner DOM. See issue #142.
  void _createTemplateAttributePlaceholder(Element node, TemplateInfo result) {
    result.removeAttributes.add('template');
    var contentNode = node.clone();
    node.attributes.clear();
    contentNode.nodes.addAll(node.nodes);

    // Create a new ElementInfo that is a child of "result" -- the
    // placeholder node. This will become result.contentInfo.
    visitElementInfo(_createElementInfo(contentNode, result));
  }

  void visitAttribute(ElementInfo info, String name, String value) {
    if (name.startsWith('on')) {
      _readEventHandler(info, name, value);
      return;
    } else if (name.startsWith('bind-')) {
      // Strip leading "bind-"
      var attrName = name.substring(5);
      if (_readTwoWayBinding(info, attrName, value)) {
        info.removeAttributes.add(name);
      }
      return;
    }

    AttributeInfo attrInfo;
    if (name == 'style') {
      attrInfo = _readStyleAttribute(info, value);
    } else if (name == 'class') {
      attrInfo = _readClassAttribute(info, value);
    } else {
      attrInfo = _readAttribute(info, name, value);
    }

    if (attrInfo != null) {
      info.attributes[name] = attrInfo;
    }

    // Any component's custom pseudo-element(s) defined?
    if (name == 'pseudo' && _currentInfo is ComponentInfo) {
      _processPseudoAttribute(info.node, value.split(' '));
    }
  }

  void _processPseudoAttribute(Node node, List<String> values) {
    List mangledValues = [];
    for (var pseudoElement in values) {
      if (_pseudoElements.containsKey(pseudoElement)) continue;

      _uniqueIds.moveNext();
      var newValue = "${pseudoElement}_${_uniqueIds.current}";
      _pseudoElements[pseudoElement] = newValue;
      // Mangled name of pseudo-element.
      mangledValues.add(newValue);

      if (!pseudoElement.startsWith('x-')) {
        // TODO(terry): The name must start with x- otherwise it's not a custom
        //              pseudo-element.  May want to relax since components no
        //              longer need to start with x-.  See isse #509 on
        //              pseudo-element prefix.
        _messages.warning("Custom pseudo-element must be prefixed with 'x-'.",
            node.sourceSpan);
      }
    }

    // Update the pseudo attribute with the new mangled names.
    node.attributes['pseudo'] = mangledValues.join(' ');
  }

  /**
   * Support for inline event handlers that take expressions.
   * For example: `on-double-click=myHandler($event, todo)`.
   */
  void _readEventHandler(ElementInfo info, String name, String value) {
    if (!name.startsWith('on-')) {
      // TODO(jmesserly): do we need an option to suppress this warning?
      _messages.warning('Event handler $name will be interpreted as an inline '
          'JavaScript event handler. Use the form '
          'on-event-name="handlerName(\$event)" if you want a Dart handler '
          'that will automatically update the UI based on model changes.',
          info.node.sourceSpan);
      return;
    }

    if (name == 'on-key-down' || name == 'on-key-up' ||
        name == 'on-key-press') {
      value = '\$event = new autogenerated.KeyEvent(\$event); $value';
    }

    _addEvent(info, toCamelCase(name), (elem) => value);
    info.removeAttributes.add(name);
  }

  EventInfo _addEvent(ElementInfo info, String name, ActionDefinition action) {
    var events = info.events.putIfAbsent(name, () => <EventInfo>[]);
    var eventInfo = new EventInfo(name, action);
    events.add(eventInfo);
    return eventInfo;
  }

  // http://dev.w3.org/html5/spec/the-input-element.html#the-input-element
  /** Support for two-way bindings. */
  bool _readTwoWayBinding(ElementInfo info, String name, String value) {
    var elem = info.node;
    var binding = new BindingInfo.fromText(value);

    // Find the HTML tag name.
    var isInput = info.baseTagName == 'input';
    var isTextArea = info.baseTagName == 'textarea';
    var isSelect = info.baseTagName == 'select';
    var inputType = elem.attributes['type'];

    String eventStream;

    // Special two-way binding logic for input elements.
    if (isInput && name == 'checked') {
      if (inputType == 'radio') {
        if (!_isValidRadioButton(info)) return false;
      } else if (inputType != 'checkbox') {
        _messages.error('checked is only supported in HTML with type="radio" '
            'or type="checked".', info.node.sourceSpan);
        return false;
      }

      // Both 'click' and 'change' seem reliable on all the modern browsers.
      eventStream = 'onChange';
    } else if (isSelect && (name == 'selected-index' || name == 'value')) {
      eventStream = 'onChange';
    } else if (isInput && name == 'value' && inputType == 'radio') {
      return _addRadioValueBinding(info, binding);
    } else if (isInput && name == 'files' && inputType == 'file') {
      eventStream = 'onChange';
    } else if (isTextArea && name == 'value' || isInput &&
        (name == 'value' || name == 'value-as-date' ||
        name == 'value-as-number')) {

      // Input event is fired more frequently than "change" on some browsers.
      // We want to update the value for each keystroke.
      eventStream = 'onInput';
    } else if (info.component != null) {
      // Assume we are binding a field on the component.
      // TODO(jmesserly): validate this assumption about the user's code by
      // using compile time mirrors.

      _checkDuplicateAttribute(info, name);
      info.attributes[name] = new AttributeInfo([binding],
          customTwoWayBinding: true);
      return true;

    } else {
      _messages.error('Unknown two-way binding attribute $name. Ignored.',
          info.node.sourceSpan);
      return false;
    }

    _checkDuplicateAttribute(info, name);

    info.attributes[name] = new AttributeInfo([binding]);
    _addEvent(info, eventStream,
        (e) => '${binding.exp} = $e.${findDomField(info, name)}');
    return true;
  }

  void _checkDuplicateAttribute(ElementInfo info, String name) {
    if (info.node.attributes[name] != null) {
      _messages.warning('Duplicate attribute $name. You should provide either '
          'the two-way binding or the attribute itself. The attribute will be '
          'ignored.', info.node.sourceSpan);
      info.removeAttributes.add(name);
    }
  }

  bool _isValidRadioButton(ElementInfo info) {
    if (info.attributes['checked'] == null) return true;

    _messages.error('Radio buttons cannot have both "checked" and "value" '
        'two-way bindings. Either use checked:\n'
        '  <input type="radio" bind-checked="myBooleanVar">\n'
        'or value:\n'
        '  <input type="radio" bind-value="myStringVar" value="theValue">',
        info.node.sourceSpan);
    return false;
  }

  /**
   * Radio buttons use the "value" and "bind-value" fields.
   * The "value" attribute is assigned to the binding expression when checked,
   * and the checked field is updated if "value" matches the binding expression.
   */
  bool _addRadioValueBinding(ElementInfo info, BindingInfo binding) {
    if (!_isValidRadioButton(info)) return false;

    // TODO(jmesserly): should we read the element's "value" at runtime?
    var radioValue = info.node.attributes['value'];
    if (radioValue == null) {
      _messages.error('Radio button bindings need "bind-value" and "value".'
          'For example: '
          '<input type="radio" bind-value="myStringVar" value="theValue">',
          info.node.sourceSpan);
      return false;
    }

    radioValue = escapeDartString(radioValue);
    info.attributes['checked'] = new AttributeInfo(
        [new BindingInfo("${binding.exp} == '$radioValue'", false)]);
    _addEvent(info, 'onChange', (e) => "${binding.exp} = '$radioValue'");
    return true;
  }

  /**
   * Data binding support in attributes. Supports multiple bindings.
   * This is can be used for any attribute, but a typical use case would be
   * URLs, for example:
   *
   *       href="#{item.href}"
   */
  AttributeInfo _readAttribute(ElementInfo info, String name, String value) {
    var parser = new BindingParser(value);
    if (!parser.moveNext()) {
      if (info.component == null || globalAttributes.contains(name) ||
          name == 'is') {
        return null;
      }
      return new AttributeInfo([], textContent: [parser.textContent]);
    }

    info.removeAttributes.add(name);
    var bindings = <BindingInfo>[];
    var content = <String>[];
    parser.readAll(bindings, content);

    // Use a simple attriubte binding if we can.
    // This kind of binding works for non-String values.
    if (bindings.length == 1 && content[0] == '' && content[1] == '') {
      return new AttributeInfo(bindings);
    }

    // Otherwise do a text attribute that performs string interpolation.
    return new AttributeInfo(bindings, textContent: content);
  }

  /**
   * Special support to bind style properties of the forms:
   *     style="{{mapValue}}"
   *     style="property: {{value1}}; other-property: {{value2}}"
   */
  AttributeInfo _readStyleAttribute(ElementInfo info, String value) {
    var parser = new BindingParser(value);
    if (!parser.moveNext()) return null;

    var bindings = <BindingInfo>[];
    var content = <String>[];
    parser.readAll(bindings, content);

    // Use a style attribute binding if we can.
    // This kind of binding works for map values.
    if (bindings.length == 1 && content[0] == '' && content[1] == '') {
      return new AttributeInfo(bindings, isStyle: true);
    }

    // Otherwise do a text attribute that performs string interpolation.
    return new AttributeInfo(bindings, textContent: content);
  }

  /**
   * Special support to bind each css class separately in attributes of the
   * form:
   *     class="{{class1}} class2 {{class3}} {{class4}}"
   */
  AttributeInfo _readClassAttribute(ElementInfo info, String value) {
    var parser = new BindingParser(value);
    if (!parser.moveNext()) return null;

    var bindings = <BindingInfo>[];
    var content = <String>[];
    parser.readAll(bindings, content);

    // Update class attributes to only have non-databound class names for
    // attributes for the HTML.
    info.node.attributes['class'] = content.join('');

    return new AttributeInfo(bindings, isClass: true);
  }

  void visitText(Text text) {
    var parser = new BindingParser(text.value);
    if (!parser.moveNext()) {
      if (!_keepIndentationSpaces) {
        text.value = trimOrCompact(text.value);
      }
      if (text.value != '') new TextInfo(text, _parent);
      return;
    }

    _parent.childrenCreatedInCode = true;

    // We split [text] so that each binding has its own text node.
    var node = text.parent;
    do {
      _addRawTextContent(parser.textContent);
      var placeholder = new Text('');
      _uniqueIds.moveNext();
      var id = '__binding${_uniqueIds.current}';
      new TextInfo(placeholder, _parent, parser.binding, id);
    } while (parser.moveNext());

    _addRawTextContent(parser.textContent);
  }

  void _addRawTextContent(String content) {
    if (!_keepIndentationSpaces) {
      content = trimOrCompact(content);
    }
    if (content != '') {
      new TextInfo(new Text(content), _parent);
    }
  }

  /**
   * Normalizes references in [info]. On the [analyzeDefinitions] phase, the
   * analyzer extracted names of files and components. Here we link those names
   * to actual info classes. In particular:
   *   * we initialize the [FileInfo.components] map in [info] by importing all
   *     [declaredComponents],
   *   * we scan all [info.componentLinks] and import their
   *     [info.declaredComponents], using [files] to map the href to the file
   *     info. Names in [info] will shadow names from imported files.
   *   * we fill [LibraryInfo.externalCode] on each component declared in
   *     [info].
   */
  void _normalize(FileInfo info, Map<String, FileInfo> files) {
    _attachExtenalScript(info, files);

    for (var component in info.declaredComponents) {
      _addComponent(info, component);
      _attachExtenalScript(component, files);
    }

    for (var link in info.componentLinks) {
      var file = files[link.resolvedPath];
      // We already issued an error for missing files.
      if (file == null) continue;
      file.declaredComponents.forEach((c) => _addComponent(info, c));
    }
  }

  /**
   * Stores a direct reference in [info] to a dart source file that was loaded
   * in a script tag with the 'src' attribute.
   */
  void _attachExtenalScript(LibraryInfo info, Map<String, FileInfo> files) {
    var externalFile = info.externalFile;
    if (externalFile != null) {
      info.externalCode = files[externalFile.resolvedPath];
      if (info.externalCode != null) info.externalCode.htmlFile = info;
    }
  }

  /** Adds a component's tag name to the names in scope for [fileInfo]. */
  void _addComponent(FileInfo fileInfo, ComponentSummary component) {
    var existing = fileInfo.components[component.tagName];
    if (existing != null) {
      if (existing == component) {
        // This is the same exact component as the existing one.
        return;
      }

      if (existing is ComponentInfo && component is! ComponentInfo) {
        // Components declared in [fileInfo] shadow component names declared in
        // imported files.
        return;
      }

      if (existing.hasConflict) {
        // No need to report a second error for the same name.
        return;
      }

      existing.hasConflict = true;

      if (component is ComponentInfo) {
        _messages.error('duplicate custom element definition for '
            '"${component.tagName}".', existing.sourceSpan);
        _messages.error('duplicate custom element definition for '
            '"${component.tagName}" (second location).', component.sourceSpan);
      } else {
        _messages.error('imported duplicate custom element definitions '
            'for "${component.tagName}".', existing.sourceSpan);
        _messages.error('imported duplicate custom element definitions '
            'for "${component.tagName}" (second location).',
            component.sourceSpan);
      }
    } else {
      fileInfo.components[component.tagName] = component;
    }
  }
}

/** A visitor that finds `<link rel="import">` and `<element>` tags.  */
class _ElementLoader extends TreeVisitor {
  final FileInfo _fileInfo;
  LibraryInfo _currentInfo;
  String _packageRoot;
  bool _inHead = false;
  Messages _messages;

  /**
   * Adds emitted warning/error messages to [_messages]. [_messages]
   * must not be null.
   */
  _ElementLoader(this._fileInfo, this._packageRoot, this._messages) {
    assert(this._messages != null);
    _currentInfo = _fileInfo;
  }

  void visitElement(Element node) {
    switch (node.tagName) {
      case 'link': visitLinkElement(node); break;
      case 'element': visitElementElement(node); break;
      case 'script': visitScriptElement(node); break;
      case 'head':
        var savedInHead = _inHead;
        _inHead = true;
        super.visitElement(node);
        _inHead = savedInHead;
        break;
      default: super.visitElement(node); break;
    }
  }

  /**
   * Process `link rel="import"` as specified in:
   * <https://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/components/index.html#link-type-component>
   */
  void visitLinkElement(Element node) {
    var rel = node.attributes['rel'];
    if (rel != 'component' && rel != 'components' &&
        rel != 'import' && rel != 'stylesheet') return;

    if (!_inHead) {
      _messages.warning('link rel="$rel" only valid in '
          'head.', node.sourceSpan);
      return;
    }

    if (rel == 'component' || rel == 'components') {
      _messages.warning('import syntax is changing, use '
          'rel="import" instead of rel="$rel".', node.sourceSpan);
    }

    var href = node.attributes['href'];
    if (href == null || href == '') {
      _messages.warning('link rel="$rel" missing href.',
          node.sourceSpan);
      return;
    }

    bool isStyleSheet = rel == 'stylesheet';
    var urlInfo = UrlInfo.resolve(href, _fileInfo.inputUrl, node.sourceSpan,
        _packageRoot, _messages, ignoreAbsolute: isStyleSheet);
    if (urlInfo == null) return;
    if (isStyleSheet) {
      _fileInfo.styleSheetHrefs.add(urlInfo);
    } else {
      _fileInfo.componentLinks.add(urlInfo);
    }
  }

  void visitElementElement(Element node) {
    // TODO(jmesserly): what do we do in this case? It seems like an <element>
    // inside a Shadow DOM should be scoped to that <template> tag, and not
    // visible from the outside.
    if (_currentInfo is ComponentInfo) {
      _messages.error('Nested component definitions are not yet supported.',
          node.sourceSpan);
      return;
    }

    var tagName = node.attributes['name'];
    var extendsTag = node.attributes['extends'];
    var templateNodes = node.nodes.where((n) => n.tagName == 'template');

    if (tagName == null) {
      _messages.error('Missing tag name of the component. Please include an '
          'attribute like \'name="your-tag-name"\'.',
          node.sourceSpan);
      return;
    }

    if (extendsTag == null) {
      // From the spec:
      // http://dvcs.w3.org/hg/webcomponents/raw-file/tip/spec/custom/index.html#extensions-to-document-interface
      // If PROTOTYPE is null, let PROTOTYPE be the interface prototype object
      // for the HTMLSpanElement interface.
      extendsTag = 'span';
    }

    var template = null;
    if (templateNodes.length == 1) {
      template = templateNodes.single;
    } else {
      _messages.error('an <element> should have exactly one <template> child',
          node.sourceSpan);
    }

    var component = new ComponentInfo(node, _fileInfo, tagName, extendsTag,
        template);

    _fileInfo.declaredComponents.add(component);

    var lastInfo = _currentInfo;
    _currentInfo = component;
    super.visitElement(node);
    _currentInfo = lastInfo;
  }


  void visitScriptElement(Element node) {
    var scriptType = node.attributes['type'];
    var src = node.attributes["src"];

    if (scriptType == null) {
      // Note: in html5 leaving off type= is fine, but it defaults to
      // text/javascript. Because this might be a common error, we warn about it
      // in two cases:
      //   * an inline script tag in a web component
      //   * a script src= if the src file ends in .dart (component or not)
      //
      // The hope is that neither of these cases should break existing valid
      // code, but that they'll help component authors avoid having their Dart
      // code accidentally interpreted as JavaScript by the browser.
      if (src == null && _currentInfo is ComponentInfo) {
        _messages.warning('script tag in component with no type will '
            'be treated as JavaScript. Did you forget type="application/dart"?',
            node.sourceSpan);
      }
      if (src != null && src.endsWith('.dart')) {
        _messages.warning('script tag with .dart source file but no type will '
            'be treated as JavaScript. Did you forget type="application/dart"?',
            node.sourceSpan);
      }
      return;
    }

    if (scriptType != 'application/dart') {
      if (_currentInfo is ComponentInfo) {
        // TODO(jmesserly): this warning should not be here, but our compiler
        // does the wrong thing and it could cause surprising behavior, so let
        // the user know! See issue #340 for more info.
        // What we should be doing: leave JS component untouched by compiler.
        _messages.warning('our custom element implementation does not support '
            'JavaScript components yet. If this is affecting you please let us '
            'know at https://github.com/dart-lang/web-ui/issues/340.',
            node.sourceSpan);
      }

      return;
    }

    if (src != null) {
      if (!src.endsWith('.dart')) {
        _messages.warning('"application/dart" scripts should '
            'use the .dart file extension.',
            node.sourceSpan);
      }

      if (node.innerHtml.trim() != '') {
        _messages.error('script tag has "src" attribute and also has script '
            'text.', node.sourceSpan);
      }

      if (_currentInfo.codeAttached) {
        _tooManyScriptsError(node);
      } else {
        _currentInfo.externalFile = UrlInfo.resolve(src, _fileInfo.inputUrl,
            node.sourceSpan, _packageRoot, _messages);
      }
      return;
    }

    if (node.nodes.length == 0) return;

    // I don't think the html5 parser will emit a tree with more than
    // one child of <script>
    assert(node.nodes.length == 1);
    Text text = node.nodes[0];

    if (_currentInfo.codeAttached) {
      _tooManyScriptsError(node);
    } else if (_currentInfo == _fileInfo && !_fileInfo.isEntryPoint) {
      _messages.warning('top-level dart code is ignored on '
          ' HTML pages that define components, but are not the entry HTML '
          'file.', node.sourceSpan);
    } else {
      _currentInfo.inlinedCode = parseDartCode(
          _currentInfo.dartCodeUrl.resolvedPath, text.value, _messages,
          text.sourceSpan.start);
      if (_currentInfo.userCode.partOf != null) {
        _messages.error('expected a library, not a part.',
            node.sourceSpan);
      }
    }
  }

  void _tooManyScriptsError(Node node) {
    var location = _currentInfo is ComponentInfo ?
        'a custom element declaration' : 'the top-level HTML page';

    _messages.error('there should be only one dart script tag in $location.',
        node.sourceSpan);
  }
}


/**
 * Parses double-curly data bindings within a string, such as
 * `foo {{bar}} baz {{quux}}`.
 *
 * Note that a double curly always closes the binding expression, and nesting
 * is not supported. This seems like a reasonable assumption, given that these
 * will be specified for HTML, and they will require a Dart or JavaScript
 * parser to parse the expressions.
 */
class BindingParser {
  final String text;
  int previousEnd;
  int start;
  int end = 0;

  BindingParser(this.text);

  int get length => text.length;

  String get textContent {
    if (start == null) throw new StateError('iteration not started');
    return text.substring(previousEnd, start);
  }

  BindingInfo get binding {
    if (start == null) throw new StateError('iteration not started');
    if (end < 0) throw new StateError('no more bindings');
    return new BindingInfo.fromText(text.substring(start + 2, end - 2));
  }

  bool moveNext() {
    if (end < 0) return false;

    previousEnd = end;
    start = text.indexOf('{{', end);
    if (start < 0) {
      end = -1;
      start = length;
      return false;
    }

    end = text.indexOf('}}', start);
    if (end < 0) {
      start = length;
      return false;
    }
    // For consistency, start and end both include the curly braces.
    end += 2;
    return true;
  }

  /**
   * Parses all bindings and contents and store them in the provided arguments.
   */
  void readAll(List<BindingInfo> bindings, List<String> content) {
    if (start == null) moveNext();
    if (start < length) {
      do {
        bindings.add(binding);
        content.add(textContent);
      } while (moveNext());
    }
    content.add(textContent);
  }
}

void analyzeCss(String packageRoot, List<SourceFile> files,
                Map<String, FileInfo> info, Map<String, String> pseudoElements,
                Messages messages, {warningsAsErrors: false}) {
  var analyzer = new _AnalyzerCss(packageRoot, info, pseudoElements, messages,
      warningsAsErrors);
  for (var file in files) analyzer.process(file);
  analyzer.normalize();
}

class _AnalyzerCss {
  final String packageRoot;
  final Map<String, FileInfo> info;
  final Map<String, String> _pseudoElements;
  final Messages _messages;
  final bool _warningsAsErrors;

  Set<StyleSheet> allStyleSheets = new Set<StyleSheet>();

  /**
   * [_pseudoElements] list of known pseudo attributes found in HTML, any
   * CSS pseudo-elements 'name::custom-element' is mapped to the manged name
   * associated with the pseudo-element key.
   */
  _AnalyzerCss(this.packageRoot, this.info, this._pseudoElements,
               this._messages, this._warningsAsErrors);

  /**
   * Run the analyzer on every file that is a style sheet or any component that
   * has a style tag.
   */
  void process(SourceFile file) {
    var fileInfo = info[file.path];
    if (file.isStyleSheet || fileInfo.styleSheets.length > 0) {
      var styleSheets = processVars(fileInfo);

      // Add to list of all style sheets analyzed.
      allStyleSheets.addAll(styleSheets);
    }

    // Process any components.
    for (var component in fileInfo.declaredComponents) {
      var all = processVars(component);

      // Add to list of all style sheets analyzed.
      allStyleSheets.addAll(all);
    }

    processCustomPseudoElements();
  }

  void normalize() {
    // Remove all var definitions for all style sheets analyzed.
    for (var tree in allStyleSheets) new RemoveVarDefinitions().visitTree(tree);
  }

  List<StyleSheet> processVars(var libraryInfo) {
    // Get list of all stylesheet(s) dependencies referenced from this file.
    var styleSheets = _dependencies(libraryInfo).toList();

    var errors = [];
    css.analyze(styleSheets, errors: errors, options:
      [_warningsAsErrors ? '--warnings_as_errors' : '', 'memory']);

    // Print errors as warnings.
    for (var e in errors) {
      _messages.warning(e.message, e.span);
    }

    // Build list of all var definitions.
    Map varDefs = new Map();
    for (var tree in styleSheets) {
      var allDefs = (new VarDefinitions()..visitTree(tree)).found;
      allDefs.forEach((key, value) {
        varDefs[key] = value;
      });
    }

    // Resolve all definitions to a non-VarUsage (terminal expression).
    varDefs.forEach((key, value) {
      for (var expr in (value.expression as Expressions).expressions) {
        var def = findTerminalVarDefinition(varDefs, value);
        varDefs[key] = def;
      }
    });

    // Resolve all var usages.
    for (var tree in styleSheets) new ResolveVarUsages(varDefs).visitTree(tree);

    return styleSheets;
  }

  processCustomPseudoElements() {
    var polyFiller = new PseudoElementExpander(_pseudoElements);
    for (var tree in allStyleSheets) {
      polyFiller.visitTree(tree);
    }
  }

  /**
   * Given a component or file check if any stylesheets referenced.  If so then
   * return a list of all referenced stylesheet dependencies (@imports or <link
   * rel="stylesheet" ..>).
   */
  Set<StyleSheet> _dependencies(var libraryInfo, {Set<StyleSheet> seen}) {
    if (seen == null) seen = new Set();

    // Used to resolve all pathing information.
    var inputUrl = libraryInfo is FileInfo
        ? libraryInfo.inputUrl
        : (libraryInfo as ComponentInfo).declaringFile.inputUrl;

    for (var styleSheet in libraryInfo.styleSheets) {
      if (!seen.contains(styleSheet)) {
        // TODO(terry): VM uses expandos to implement hashes.  Currently, it's a
        //              linear (not constant) time cost (see dartbug.com/5746).
        //              If this bug isn't fixed and performance show's this a
        //              a problem we'll need to implement our own hashCode or
        //              use a different key for better perf.
        // Add the stylesheet.
        seen.add(styleSheet);

        // Any other imports in this stylesheet?
        var urlInfos = findImportsInStyleSheet(styleSheet, packageRoot,
            inputUrl, _messages);

        // Process other imports in this stylesheets.
        for (var importSS in urlInfos) {
          var importInfo = info[importSS.resolvedPath];
          if (importInfo != null) {
            // Add all known stylesheets processed.
            seen.addAll(importInfo.styleSheets);
            // Find dependencies for stylesheet referenced with a
            // @import
            for (var ss in importInfo.styleSheets) {
              var urls = findImportsInStyleSheet(ss, packageRoot, inputUrl,
                  _messages);
              for (var url in urls) {
                _dependencies(info[url.resolvedPath], seen: seen);
              }
            }
          }
        }
      }
    }

    return seen;
  }
}
