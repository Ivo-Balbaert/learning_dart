// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library web_ui.src.utils_observe;

import 'dart:collection';
import 'dart:isolate';

// TODO(jmesserly): helpers to combine hash codes. Reuse these from somewhere.
hash2(x, y) => x.hashCode * 31 + y.hashCode;

hash3(x, y, z) => hash2(hash2(x, y), z);

hash4(w, x, y, z) => hash2(hash2(w, x), hash2(y, z));

// TODO(jmesserly): replace with something in dart:async, as long as it is based
// on window.setImmediate/mutation observers/postMessage and not setTimeout(0)
// Maybe we can use Future.value? We need it to be fast (next microtask)
// like this though: http://dartbug.com/8757.
/**
 * Adds an event to call [callback], so the event loop will call this after the
 * current stack has unwound.
 */
void setImmediate(void callback()) {
  var port = new ReceivePort();
  port.receive((msg, sendPort) {
    port.close();
    callback();
  });
  port.toSendPort().send(null);
}

class Arrays {
  static void copy(List src, int srcStart,
                   List dst, int dstStart, int count) {
    if (srcStart == null) srcStart = 0;
    if (dstStart == null) dstStart = 0;

    if (srcStart < dstStart) {
      for (int i = srcStart + count - 1, j = dstStart + count - 1;
           i >= srcStart; i--, j--) {
        dst[j] = src[i];
      }
    } else {
      for (int i = srcStart, j = dstStart; i < srcStart + count; i++, j++) {
        dst[j] = src[i];
      }
    }
  }

  static void rangeCheck(List a, int start, int length) {
    if (length < 0) {
      throw new ArgumentError("negative length $length");
    }
    if (start < 0 ) {
      String message = "$start must be greater than or equal to 0";
      throw new RangeError(message);
    }
    if (start + length > a.length) {
      String message = "$start + $length must be in the range [0..${a.length})";
      throw new RangeError(message);
    }
  }
}

// TODO(jmesserly): bogus type to workaround spurious VM bug with generic base
// class and mixins.
abstract class IterableWorkaround extends IterableBase<dynamic> {}
abstract class ListMixinWorkaround extends ListMixin<dynamic> {}
