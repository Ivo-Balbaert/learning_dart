// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A library for observing changes to observable Dart objects.
 * Similar in spirit to EcmaScript Harmony
 * [Object.observe](http://wiki.ecmascript.org/doku.php?id=harmony:observe), but
 * able to observe expressions and not just objects, so long as the expressions
 * are computed from observable objects.
 *
 * See the `observable` annotation and the `observe` function.
 */
// Note: one intentional difference from Harmony Object.observe is that our
// change batches are tracked on a per-observed expression basis, instead of
// per-observer basis.
// We do this because there is no cheap way to store data on a Dart
// function (Expando uses linear search on the VM: http://dartbug.com/7558).
// This difference means that a given observer will be called with one batch of
// changes for each object it is observing.
// TODO(jmesserly): this behavior is not ideal. It's really powerful to be able
// to get all changes in one "transaction". We should look at alternate
// approaches.
library observe;

export 'observe/list.dart';
export 'observe/map.dart';
export 'observe/reference.dart';
export 'observe/set.dart';

export 'observe/observable.dart'
    // Hide methods that are only used when implementing Observable:
    hide hasObservers, observeReads, notifyChange, notifyRead;
