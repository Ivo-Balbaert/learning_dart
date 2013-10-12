// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observe;

/**
 * Base class implementing [Observable] object that performs its own change
 * notifications, and does not need to be considered by [Observable.dirtyCheck].
 *
 * When a field, property, or indexable item is changed, a derived class should
 * call [notifyPropertyChange]. See that method for an example.
 */
typedef ChangeNotifierBase = Object with ChangeNotifierMixin;

/**
 * Mixin implementing [Observable] object that performs its own change
 * notifications, and does not need to be considered by [Observable.dirtyCheck].
 *
 * When a field, property, or indexable item is changed, a derived class should
 * call [notifyPropertyChange]. See that method for an example.
 */
abstract class ChangeNotifierMixin implements Observable {
  StreamController _changes;
  List<ChangeRecord> _records;

  Stream<List<ChangeRecord>> get changes {
    if (_changes == null) {
      _changes = new StreamController.broadcast(sync: true,
          onListen: _observed, onCancel: _unobserved);
    }
    return _changes.stream;
  }

  // TODO(jmesserly): should these be public? They're useful lifecycle methods
  // for subclasses. Ideally they'd be protected.
  /**
   * Override this method to be called when the [changes] are first observed.
   */
  void _observed() {}

  /**
   * Override this method to be called when the [changes] are no longer being
   * observed.
   */
  void _unobserved() {}

  bool deliverChanges() {
    var records = _records;
    _records = null;
    if (hasObservers && records != null) {
      _changes.add(new UnmodifiableListView<ChangeRecord>(records));
      return true;
    }
    return false;
  }

  /**
   * True if this object has any observers, and should call
   * [notifyPropertyChange] for changes.
   */
  bool get hasObservers => _changes != null && _changes.hasListener;

  /**
   * Notify that the field [name] of this object has been changed.
   *
   * The [oldValue] and [newValue] are also recorded. If the two values are
   * identical, no change will be recorded.
   *
   * For convenience this returns [newValue]. This makes it easy to use in a
   * setter:
   *
   *     var _myField;
   *     get myField => _myField;
   *     set myField(value) {
   *       _myField = notifyPropertyChange(
   *           const Symbol('myField'), _myField, value);
   *     }
   */
  notifyPropertyChange(Symbol field, Object oldValue, Object newValue)
      => _notifyPropertyChange(this, field, oldValue, newValue);

  void notifyChange(ChangeRecord record) {
    if (!hasObservers) return;

    if (_records == null) {
      _records = [];
      runAsync(deliverChanges);
    }
    _records.add(record);
  }
}
