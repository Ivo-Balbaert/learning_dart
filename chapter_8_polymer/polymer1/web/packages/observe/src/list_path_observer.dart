// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observe;

const _VALUE = const Symbol('value');

// Inspired by ArrayReduction at:
// https://raw.github.com/rafaelw/ChangeSummary/master/util/array_reduction.js
// The main difference is we support anything on the rich Dart Iterable API.

/**
 * Observes a path starting from each item in the list.
 */
class ListPathObserver<E, P> extends ChangeNotifierBase {
  final ObservableList<E> list;
  final String _itemPath;
  final List<PathObserver> _observers = <PathObserver>[];
  final List<StreamSubscription> _subs = <StreamSubscription>[];
  StreamSubscription _sub;
  bool _scheduled = false;
  Iterable<P> _value;

  ListPathObserver(this.list, String path)
      : _itemPath = path {

    _sub = list.changes.listen((records) {
      for (var record in records) {
        if (record is ListChangeRecord) {
          _observeItems(record.addedCount - record.removedCount);
        }
      }
      _scheduleReduce(null);
    });

    _observeItems(list.length);
    _reduce();
  }

  Iterable<P> get value => _value;

  void dispose() {
    if (_sub != null) _sub.cancel();
    _subs.forEach((s) => s.cancel());
    _subs.clear();
  }

  void _reduce() {
    _scheduled = false;
    _value = _observers.map((o) => o.value);
    notifyChange(new PropertyChangeRecord(_VALUE));
  }

  void _scheduleReduce(_) {
    if (_scheduled) return;
    _scheduled = true;
    runAsync(_reduce);
  }

  void _observeItems(int lengthAdjust) {
    if (lengthAdjust > 0) {
      for (int i = 0; i < lengthAdjust; i++) {
        int len = _observers.length;
        var pathObs = new PathObserver(list, '$len.$_itemPath');
        _subs.add(pathObs.changes.listen(_scheduleReduce));
        _observers.add(pathObs);
      }
    } else if (lengthAdjust < 0) {
      for (int i = 0; i < -lengthAdjust; i++) {
        _subs.removeLast().cancel();
      }
      int len = _observers.length;
      _observers.removeRange(len + lengthAdjust, len);
    }
  }
}
