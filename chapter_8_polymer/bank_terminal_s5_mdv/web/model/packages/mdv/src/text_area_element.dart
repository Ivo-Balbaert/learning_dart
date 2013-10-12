// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of mdv;

/** Extensions to the [TextAreaElement] API. */
class _TextAreaElementExtension extends _ElementExtension {
  _TextAreaElementExtension(TextAreaElement node) : super(node);

  TextAreaElement get node => super.node;

  NodeBinding createBinding(String name, model, String path) {
    if (name == 'value') {
      // TODO(rafaelw): Maybe template should remove all binding instructions.
      node.attributes.remove(name);
      return new _ValueBinding(node, model, path);
    }
    return super.createBinding(name, model, path);
  }
}
