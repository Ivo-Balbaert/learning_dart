// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library web_ui.observe.list;

import 'observable.dart';
import 'package:web_ui/src/utils_observe.dart' show Arrays, ListMixinWorkaround;

/**
 * Represents an observable list of model values. If any items are added,
 * removed, or replaced, then observers that are registered with
 * [observe] will be notified.
 */
class ObservableList<E> extends ListMixinWorkaround with Observable
    implements List<E> {

  /** The inner [List<E>] with the actual storage. */
  final List<E> _list;

  /**
   * Creates an observable list of the given [length].
   *
   * If no [length] argument is supplied an extendable list of
   * length 0 is created.
   *
   * If a [length] argument is supplied, a fixed size list of that
   * length is created.
   */
  ObservableList([int length])
      : _list = length != null ? new List<E>(length) : <E>[];

  /**
   * Creates an observable list with the elements of [other]. The order in
   * the list will be the order provided by the iterator of [other].
   */
  factory ObservableList.from(Iterable<E> other) =>
      new ObservableList<E>()..addAll(other);

  int get length {
    if (observeReads) notifyRead(this, ChangeRecord.FIELD, 'length');
    return _list.length;
  }

  set length(int value) {
    int len = _list.length;
    if (len == value) return;

    // Produce notifications if needed
    if (hasObservers(this)) {
      if (value < len) {
        // Remove items, then adjust length. Note the reverse order.
        for (int i = len - 1; i >= value; i--) {
          notifyChange(this, ChangeRecord.REMOVE, i, _list[i], null);
        }
        notifyChange(this, ChangeRecord.FIELD, 'length', len, value);
      } else {
        // Adjust length then add items
        notifyChange(this, ChangeRecord.FIELD, 'length', len, value);
        for (int i = len; i < value; i++) {
          notifyChange(this, ChangeRecord.INSERT, i, null, null);
        }
      }
    }

    _list.length = value;
  }

  E operator [](int index) {
    if (observeReads) notifyRead(this, ChangeRecord.INDEX, index);
    return _list[index];
  }

  operator []=(int index, E value) {
    var oldValue = _list[index];
    if (hasObservers(this)) {
      notifyChange(this, ChangeRecord.INDEX, index, oldValue, value);
    }
    _list[index] = value;
  }

  ObservableList<E> sublist(int start, [int end]) =>
    new ObservableList<E>.from(super.sublist(start, end));

  // The following three methods (add, removeRange, insertRange) are here so
  // that we can provide nice change events (insertions and removals). If we
  // use the mixin implementation, we would only report changes on indices.

  void add(E value) {
    int len = _list.length;
    if (hasObservers(this)) {
      notifyChange(this, ChangeRecord.FIELD, 'length', len, len + 1);
      notifyChange(this, ChangeRecord.INSERT, len, null, value);
    }

    _list.add(value);
  }

  // TODO(jmesserly): removeRange and insertRange will cause duplicate
  // notifcations for insert/remove in the middle. The first will be for the
  // insert/remove and the second will be for the array move. Also, setting
  // length happens after the insert/remove notifcation. I think this is
  // probably unavoidable because of how arrays work: if you insert/remove in
  // the middle you effectively change elements throughout the array.
  // Maybe we need a ChangeRecord.MOVE?

  void removeRange(int start, int length) {
    if (length == 0) return;

    Arrays.rangeCheck(this, start, length);
    if (hasObservers(this)) {
      for (int i = start; i < length; i++) {
        notifyChange(this, ChangeRecord.REMOVE, i, this[i], null);
      }
    }
    Arrays.copy(this, start + length, this, start,
        this.length - length - start);

    this.length = this.length - length;
  }

  void insertRange(int start, int length, [E initialValue]) {
    if (length == 0) return;
    if (length < 0) {
      throw new ArgumentError("invalid length specified $length");
    }
    if (start < 0 || start > this.length) throw new RangeError.value(start);

    if (hasObservers(this)) {
      for (int i = start; i < length; i++) {
        notifyChange(this, ChangeRecord.INSERT, i, null, initialValue);
      }
    }

    var oldLength = this.length;
    this.length = oldLength + length;  // Will expand if needed.
    Arrays.copy(this, start, this, start + length, oldLength - start);
    for (int i = start; i < start + length; i++) {
      this[i] = initialValue;
    }
  }

  // TODO(sigmund): every method below should be in the mixin (dartbug.com/9869)

  void insert(int index, E item) => insertRange(index, 1, item);

  E removeAt(int index) {
    E result = this[index];
    removeRange(index, 1);
    return result;
  }

  Iterable expand(Iterable f(E)) {
    throw new UnimplementedError();
    return null;
  }

  String toString() {
    if (observeReads) {
      for (int i = 0; i < length; i++) {
        notifyRead(this, ChangeRecord.INDEX, i);
      }
    }
    return _list.toString();
  }
}
