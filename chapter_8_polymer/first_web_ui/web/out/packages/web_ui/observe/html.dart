// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): can we handle this better? This seems like an unfortunate
// limitation of our read barriers.

/** Helpers for exposing dart:html as observable data. */
library web_ui.observe.html;

import 'dart:html';
import 'package:web_ui/observe.dart';

ObservableReference<String> _hash;

/** An observable version of [window.location.hash]. */
String get locationHash {
  if (_hash == null) {
    _hash = new ObservableReference(window.location.hash);

    window.onHashChange.listen(_updateLocationHash);
    window.onPopState.listen(_updateLocationHash);
  }

  return _hash.value;
}

/**
 * Pushes a new URL state, similar to the affect of clicking a link.
 * Has no effect if the [value] already equals [window.location.hash].
 */
set locationHash(String value) {
  if (value == window.location.hash) return;

  window.history.pushState(const {}, '', value);
  _updateLocationHash(null);
}


// listen on changes to #hash in the URL
// Note: listen on both popState and hashChange, because IE9 doesnh't support
// history API, and it doesn't work properly on Opera 12.
// See http://dartbug.com/5483
_updateLocationHash(_) {
  if (_hash != null) {
    _hash.value = window.location.hash;
  }
}
