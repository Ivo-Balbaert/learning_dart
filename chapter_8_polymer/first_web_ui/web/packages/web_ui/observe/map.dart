// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library web_ui.observe.map;

import 'dart:collection';
import 'observable.dart';

typedef Map<K, V> MapFactory<K, V>();

// TODO(jmesserly): this needs to be faster. We currently require multiple
// lookups per key to get the old value. Most likely this needs to be based on
// a modified HashMap/LinkedHashMap/SplayTreeMap source code.
/**
 * Represents an observable map of model values. If any items are added,
 * removed, or replaced, then observers that are registered with
 * [observe] will be notified.
 */
class ObservableMap<K, V> extends Observable implements Map<K, V> {
  final Map<K, V> _map;
  _ObservableMapKeyIterable<K, V> _keys;
  _ObservableMapValueIterable<K, V> _values;

  /**
   * Creates an observable map, optionally using the provided factory
   * [createMap] to construct a custom map type.
   */
  ObservableMap({MapFactory<K, V> createMap})
      : _map = createMap != null ? createMap() : new Map<K, V>() {
    _keys = new _ObservableMapKeyIterable<K, V>(this);
    _values = new _ObservableMapValueIterable<K, V>(this);
  }

  /** Creates a new observable map using a [LinkedHashMap]. */
  // TODO(jmesserly): removed type annotation to workaround:
  // https://code.google.com/p/dart/issues/detail?id=11540
  ObservableMap.linked() : this(createMap: () => new LinkedHashMap/*<K, V>*/());

  /** Creates a new observable map using a [SplayTreeMap]. */
  ObservableMap.sorted() : this(createMap: () => new SplayTreeMap/*<K, V>*/());

  /**
   * Creates an observable map that contains all key value pairs of [other].
   */
  factory ObservableMap.from(Map/*<K, V>*/ other,
        {MapFactory/*<K, V>*/ createMap}) {
    var result = new ObservableMap/*<K, V>*/(createMap: createMap);
    other.forEach((/*K*/ key, /*V*/value) { result[key] = value; });
    return result;
  }


  Iterable<K> get keys => _keys;

  Iterable<V> get values => _values;

  int get length {
    if (observeReads) notifyRead(this, ChangeRecord.FIELD, 'length');
    return _map.length;
  }

  bool get isEmpty => length == 0;

  bool get isNotEmpty => length != 0;

  void _notifyReadKey(K key) => notifyRead(this, ChangeRecord.INDEX, key);

  void _notifyReadAll() {
    notifyRead(this, ChangeRecord.FIELD, 'length');
    _map.keys.forEach(_notifyReadKey);
  }

  bool containsValue(V value) {
    if (observeReads) _notifyReadAll();
    return _map.containsValue(value);
  }

  bool containsKey(K key) {
    if (observeReads) _notifyReadKey(key);
    return _map.containsKey(key);
  }

  V operator [](K key) {
    if (observeReads) _notifyReadKey(key);
    return _map[key];
  }

  void operator []=(K key, V value) {
    int len = _map.length;
    V oldValue = _map[key];
    _map[key] = value;
    if (hasObservers(this)) {
      if (len != _map.length) {
        notifyChange(this, ChangeRecord.FIELD, 'length', len, _map.length);
        notifyChange(this, ChangeRecord.INSERT, key, oldValue, value);
      } else if (oldValue != value) {
        notifyChange(this, ChangeRecord.INDEX, key, oldValue, value);
      }
    }
  }

  V putIfAbsent(K key, V ifAbsent()) {
    // notifyRead because result depends on if the key already exists
    if (observeReads) _notifyReadKey(key);

    int len = _map.length;
    V result = _map.putIfAbsent(key, ifAbsent);
    if (hasObservers(this) && len != _map.length) {
      notifyChange(this, ChangeRecord.FIELD, 'length', len, _map.length);
      notifyChange(this, ChangeRecord.INSERT, key, null, result);
    }
    return result;
  }

  V remove(K key) {
    // notifyRead because result depends on if the key already exists
    if (observeReads) _notifyReadKey(key);

    int len = _map.length;
    V result =  _map.remove(key);
    if (hasObservers(this) && len != _map.length) {
      notifyChange(this, ChangeRecord.REMOVE, key, result, null);
      notifyChange(this, ChangeRecord.FIELD, 'length', len, _map.length);
    }
    return result;
  }

  void addAll(Map<K, V> other) => other.forEach((k, v) { this[k] = v; });

  void clear() {
    int len = _map.length;
    if (hasObservers(this) && len > 0) {
      _map.forEach((key, value) {
        notifyChange(this, ChangeRecord.REMOVE, key, value, null);
      });
      notifyChange(this, ChangeRecord.FIELD, 'length', len, 0);
    }
    _map.clear();
  }

  void forEach(void f(K key, V value)) {
    if (observeReads) _notifyReadAll();
    _map.forEach(f);
  }

  String toString() => Maps.mapToString(this);
}

class _ObservableMapKeyIterable<K, V> extends IterableBase<K> {
  final ObservableMap<K, V> _map;
  _ObservableMapKeyIterable(this._map);

  Iterator<K> get iterator => new _ObservableMapKeyIterator<K, V>(_map);
}

class _ObservableMapKeyIterator<K, V> implements Iterator<K> {
  final ObservableMap<K, V> _map;
  final Iterator<K> _keys;
  bool _hasNext = false;

  _ObservableMapKeyIterator(ObservableMap<K, V> map)
      : _map = map,
        _keys = map._map.keys.iterator;

  bool moveNext() {
    if (observeReads) notifyRead(_map, ChangeRecord.FIELD, 'length');
    return _hasNext = _keys.moveNext();
  }

  K get current {
    var key = _keys.current;
    if (observeReads && _hasNext) _map._notifyReadKey(key);
    return key;
  }
}


class _ObservableMapValueIterable<K, V> extends IterableBase<V> {
  final ObservableMap<K, V> _map;
  _ObservableMapValueIterable(this._map);

  Iterator<V> get iterator => new _ObservableMapValueIterator<K, V>(_map);
}

class _ObservableMapValueIterator<K, V> implements Iterator<V> {
  final ObservableMap<K, V> _map;
  final Iterator<K> _keys;
  final Iterator<V> _values;
  bool _hasNext;

  _ObservableMapValueIterator(ObservableMap<K, V> map)
      : _map = map,
        _keys = map._map.keys.iterator,
        _values = map._map.values.iterator;

  bool moveNext() {
    if (observeReads) notifyRead(_map, ChangeRecord.FIELD, 'length');
    bool moreKeys = _keys.moveNext();
    bool moreValues = _values.moveNext();
    if (moreKeys != moreValues) {
      throw new StateError('keys and values should be the same length');
    }
    return _hasNext = moreValues;
  }

  V get current {
    if (observeReads && _hasNext) _map._notifyReadKey(_keys.current);
    return _values.current;
  }
}
