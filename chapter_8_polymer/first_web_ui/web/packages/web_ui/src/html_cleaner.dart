// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Part of the template compilation that concerns with simplifying HTML trees to
 * emit trimmed simple HTML code.
 */
library html_cleaner;

import 'package:html5lib/dom.dart';
import 'package:csslib/parser.dart' as css;

import 'info.dart';

/** Removes bindings and extra nodes from the HTML assciated with [info]. */
void cleanHtmlNodes(info) => new _HtmlCleaner().visit(info);

/** Remove all MDV attributes; post-analysis these attributes are not needed. */
class _HtmlCleaner extends InfoVisitor {
  ComponentInfo _component = null;

  void visitComponentInfo(ComponentInfo info) {
    // Remove the <element> tag from the tree
    if (info.elemInfo != null) info.elemInfo.node.remove();

    var oldComponent = _component;
    _component = info;
    super.visitComponentInfo(info);
    _component = oldComponent;
  }

  void visitElementInfo(ElementInfo info) {
    var node = info.node;

    info.removeAttributes.forEach(node.attributes.remove);
    info.removeAttributes.clear();


    // Normally, <template> nodes hang around in the DOM as placeholders, and
    // the user-agent style specifies that they are hidden. For browsers without
    // native template, we inject the style later.
    //
    // However, template *attributes* are used for things like this:
    //   * <td template if="condition">
    //   * <td template repeat="x in list">
    //
    // In this case, we'll leave the TD as a placeholder. So hide it.
    //
    // For now, we also support this:
    //   * <tr template iterate="x in list">
    //
    // We don't need to hide this node, because its children are expanded as
    // child nodes.
    if (info is TemplateInfo) {
      TemplateInfo t = info;
      if (!t.isTemplateElement && (t.hasCondition || t.isRepeat)) {
        node.attributes['style'] = 'display:none';
      }
    }

    if (info.childrenCreatedInCode) {
      node.nodes.clear();
    }

    if (node.tagName == 'style' && _component != null) {
      // Remove the style tag we've parsed the CSS.
      node.remove();
    }

    super.visitElementInfo(info);
  }
}
