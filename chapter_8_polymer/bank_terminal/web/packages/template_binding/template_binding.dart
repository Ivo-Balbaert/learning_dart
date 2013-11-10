// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This library provides access to the Polymer project's
 * [Data Binding](http://www.polymer-project.org/docs/polymer/databinding.html)
 * Find more information at the
 * [Polymer.dart homepage](https://www.dartlang.org/polymer-dart/).
 *
 * Extends the capabilities of the HTML Template Element by enabling it to
 * create, manage, and remove instances of content bound to data defined in
 * Dart.
 *
 * Node.bind() is a new method added to all DOM nodes which instructs them to
 * bind the named property to the data provided. These allows applications to
 * create a data model in Dart or JavaScript that DOM reacts to.
 */
library template_binding;

import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:svg' show SvgSvgElement;
import 'package:observe/observe.dart';

import 'src/binding_delegate.dart';
import 'src/node_binding.dart';

export 'src/binding_delegate.dart';
export 'src/node_binding.dart' show NodeBinding;

part 'src/element.dart';
part 'src/input_bindings.dart';
part 'src/input_element.dart';
part 'src/instance_binding_map.dart';
part 'src/node.dart';
part 'src/select_element.dart';
part 'src/template.dart';
part 'src/template_iterator.dart';
part 'src/text.dart';
part 'src/text_area_element.dart';

// TODO(jmesserly): ideally we would split TemplateBinding and Node.bind into
// two packages, but this is not easy when we are faking extension methods.
// Since TemplateElement needs to override Node.bind, it seems like the
// Node.bind layer must have some innate knowledge of TemplateBinding.

/**
 * Provides access to the data binding APIs for the [node]. For example:
 *
 *     templateBind(node).model = new MyModel();
 *
 * This is equivalent to [nodeBind], but provides access to
 * [TemplateBindExtension] APIs. [node] should be a [TemplateElement], or
 * equivalent semantic template such as:
 *
 *     <table template repeat="{{row in rows}}">
 *       <tr template repeat="{{item in row}}">
 *         <td>{{item}}</td>
 *       </tr>
 *     </table>
 */
TemplateBindExtension templateBind(Element node) => nodeBind(node);

/**
 * Like [templateBind], but intended to be used only within a custom element
 * that implements [TemplateBindExtension]. This method can be used to simulate
 * a super call. For example:
 *
 *     class CoolTemplate extends TemplateElement
 *         implements TemplateBindExtension {
 *
 *       createInstance(model, delegate) {
 *         // do something cool...
 *         // otherwise, fall back to superclass
 *         return templateBindFallback(this).createInstance(model, delegate);
 *       }
 *       ...
 *     }
 */
TemplateBindExtension templateBindFallback(Element node) =>
    nodeBindFallback(node);

/**
 * Provides access to the data binding APIs for the [node]. For example:
 *
 *     nodeBind(node).bind('checked', model, 'path.to.some.value');
 */
NodeBindExtension nodeBind(Node node) {
  return node is NodeBindExtension ? node : nodeBindFallback(node);
}

/**
 * Like [nodeBind], but intended to be used only within a custom element that
 * implements [NodeBindExtension]. This method can be used to simulate a super
 * call. For example:
 *
 *     class FancyButton extends ButtonElement implements NodeBindExtension {
 *       bind(name, model, path) {
 *         if (name == 'fancy-prop') ... // do fancy binding
 *         // otherwise, fall back to superclass
 *         return nodeBindFallback(this).bind(name, model, path);
 *       }
 *       ...
 *     }
 */
NodeBindExtension nodeBindFallback(Node node) {
  var extension = _expando[node];
  if (extension != null) return extension;

  // TODO(jmesserly): switch on localName?
  if (node is InputElement) {
    extension = new _InputElementExtension(node);
  } else if (node is SelectElement) {
    extension = new _SelectElementExtension(node);
  } else if (node is TextAreaElement) {
    extension = new _TextAreaElementExtension(node);
  } else if (node is Element) {
    if (isSemanticTemplate(node)) {
      extension = new TemplateBindExtension._(node);
    } else {
      extension = new _ElementExtension(node);
    }
  } else if (node is Text) {
    extension = new _TextExtension(node);
  } else {
    extension = new NodeBindExtension._(node);
  }

  _expando[node] = extension;
  return extension;
}


bool _isAttributeTemplate(Element n) => n.attributes.containsKey('template') &&
    _SEMANTIC_TEMPLATE_TAGS.containsKey(n.localName);

/**
 * Returns true if this node is semantically a template.
 *
 * A node is a template if [tagName] is TEMPLATE, or the node has the
 * 'template' attribute and this tag supports attribute form for backwards
 * compatibility with existing HTML parsers. The nodes that can use attribute
 * form are table elments (THEAD, TBODY, TFOOT, TH, TR, TD, CAPTION, COLGROUP
 * and COL), OPTION, and OPTGROUP.
 */
bool isSemanticTemplate(Node n) => n is Element &&
    (n.localName == 'template' || _isAttributeTemplate(n));

// TODO(jmesserly): const set would be better
const _SEMANTIC_TEMPLATE_TAGS = const {
  'caption': null,
  'col': null,
  'colgroup': null,
  'option': null,
  'optgroup': null,
  'tbody': null,
  'td': null,
  'tfoot': null,
  'th': null,
  'thead': null,
  'tr': null,
};


// TODO(jmesserly): investigate if expandos give us enough performance.

// The expando for storing our MDV extensions.
//
// In general, we need state associated with the nodes. Rather than having a
// bunch of individual expandos, we keep one per node.
//
// Aside from the potentially helping performance, it also keeps things simpler
// if we decide to integrate MDV into the DOM later, and means less code needs
// to worry about expandos.
final Expando _expando = new Expando('template_binding');
