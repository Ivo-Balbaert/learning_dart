// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library web_ui.observe.set;

import 'dart:collection';
import 'observable.dart';
import 'map.dart' show MapFactory;
import 'package:web_ui/src/utils_observe.dart' show IterableWorkaround;

/**
 * Represents an observable set of model values. If any items are added,
 * removed, or replaced, then observers that are registered with
 * [observe] will be notified.
 */
// TODO(jmesserly): ideally this could be based ObservableMap, or Dart
// would have a built in Set<->Map adapter as suggested in
// https://code.google.com/p/dart/issues/detail?id=5603
class ObservableSet<E> extends IterableWorkaround with Observable
    implements Set<E> {

  final Map<E, Object> _map;

  final MapFactory<E, Object> _createMap;

  /**
   * Creates an observable set, optionally using the provided [createMap]
   * factory to construct a custom map type.
   */
  ObservableSet({MapFactory<E, Object> createMap})
      : _map = createMap != null ? createMap() : new Map<E, Object>(),
        _createMap = createMap;

  /**
   * Creates an observable set that contains all elements of [other].
   */
  factory ObservableSet.from(Iterable<E> other,
      {MapFactory<E, Object> createMap}) {

    return new ObservableSet<E>(createMap: createMap)..addAll(other);
  }

  /**
   * Returns true if [value] is in the set.
   */
  bool contains(E value) {
    if (observeReads) notifyRead(this, ChangeRecord.INDEX, value);
    return _map.containsKey(value);
  }

  /**
   * Adds [value] into the set. The method has no effect if
   * [value] was already in the set.
   */
  void add(E value) {
    int len = _map.length;
    _map[value] = const Object();
    if (len != _map.length) {
      notifyChange(this, ChangeRecord.FIELD, 'length', len, _map.length);
      notifyChange(this, ChangeRecord.INSERT, value, null, value);
    }
  }

  /**
   * Removes [value] from the set. Returns true if [value] was
   * in the set. Returns false otherwise. The method has no effect
   * if [value] value was not in the set.
   */
  bool remove(E value) {
    // notifyRead because result depends on if the key already exists
    if (observeReads) notifyRead(this, ChangeRecord.INDEX, value);

    int len = _map.length;
    _map.remove(value);
    if (len != _map.length) {
      if (hasObservers(this)) {
        notifyChange(this, ChangeRecord.REMOVE, value, value, null);
        notifyChange(this, ChangeRecord.FIELD, 'length', len, _map.length);
      }
      return true;
    }
    return false;
  }

  /**
   * Removes all elements in the set.
   */
  void clear() {
    if (hasObservers(this)) {
      for (var value in _map.keys) {
        notifyChange(this, ChangeRecord.REMOVE, value, value, null);
      }
      notifyChange(this, ChangeRecord.FIELD, 'length', _map.length, 0);
    }
    _map.clear();
  }

  int get length {
    if (observeReads) notifyRead(this, ChangeRecord.FIELD, 'length');
    return _map.length;
  }

  bool get isEmpty => length == 0;

  Iterator<E> get iterator => new _ObservableSetIterator<E>(this);

  /**
   * Adds all the elements of the given collection to the set.
   */
  void addAll(Iterable<E> collection) => collection.forEach(add);

  /**
   * Removes all the elements of the given collection from the set.
   */
  void removeAll(Iterable collection) => collection.forEach(remove);

  void retainAll(Iterable collection) => retainWhere(collection.contains);

  void removeWhere(bool test(E element)) =>
      where(test).toList().forEach(remove);

  void retainWhere(bool test(E element)) =>
      where((e) => !test(e)).toList().forEach(remove);

  /** Returns true if [other] contains all the elements of this set. */
  bool isSubsetOf(Set<E> other) =>
      new Set<E>.from(other).containsAll(this);

  /** Returns true if this set contains all the elements of [other]. */
  bool containsAll(Set<E> other) => other.every(contains);

  /** Returns a new set which is the intersection of this set and [other]. */
  ObservableSet<E> intersection(Set<E> other) {
    var result = new ObservableSet<E>(createMap: _createMap);

    for (E value in other) {
      if (contains(value)) result.add(value);
    }
    return result;
  }

  /** Returns a new set with the elements of both this are [other]. */
  ObservableSet<E> union(Set<E> other) {
    return new ObservableSet<E>(createMap: _createMap)
        ..addAll(this)
        ..addAll(other);
  }

  /** Returns a new set with the elements of this that are not in [other]. */
  ObservableSet<E> difference(Set<E> other) {
    var result = new ObservableSet<E>(createMap: _createMap);

    for (E value in this) {
      if (!other.contains(value)) result.add(value);
    }
    return result;
  }

  String toString() {
    if (observeReads) {
      for (E value in _map.keys) {
        notifyRead(this, ChangeRecord.INDEX, value);
      }
    }
    return _map.keys.toSet().toString();
  }
}

class _ObservableSetIterator<E> implements Iterator<E> {
  final ObservableSet<E> _set;
  final Iterator<E> _iterator;
  bool _hasNext = false;

  _ObservableSetIterator(ObservableSet<E> set)
      : _set = set, _iterator = set._map.keys.iterator;

  bool moveNext() {
    // The result of this function depends on the set's length.
    _set.length;
    return _hasNext = _iterator.moveNext();
  }

  E get current {
    var result = _iterator.current;
    if (observeReads && _hasNext) notifyRead(_set, ChangeRecord.INDEX, result);
    return result;
  }
}
