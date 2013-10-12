// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This library is used to implement [Observable] types.
 *
 * It exposes lower level functionality such as [hasObservers], [observeReads]
 * [notifyChange] and [notifyRead].
 *
 * Unless you are mixing in [Observable], it is usually better to write:
 *
 *     import 'package:web_ui/observe.dart';
 */
library web_ui.observe.observable;

import 'dart:collection' hide LinkedList;
import 'list.dart';
import 'map.dart';
import 'reference.dart';
import 'set.dart';
import 'package:web_ui/src/utils_observe.dart' show setImmediate, hash3, hash4;
import 'package:web_ui/src/linked_list.dart';

/**
 * Use `@observable` to make a class observable. All fields in the class will
 * be transformed to track changes. The overhead will be minimal unless they are
 * actually being observed.
 */
const observable = const _ObservableAnnotation();

/** Callback fired when an expression changes. */
typedef void ChangeObserver(ChangeNotification e);

/** Callback fired when an [Observable] changes. */
typedef void ChangeRecordObserver(List<ChangeRecord> changes);

/** A function that unregisters the [ChangeObserver]. */
typedef void ChangeUnobserver();

/** A function that computes a value. */
typedef Object ObservableExpression();

/**
 * A notification of a change to an [ObservableExpression] that is passed to a
 * [ChangeObserver].
 */
// TODO(jmesserly): merge with ChangeRecord?
class ChangeNotification {

  /** Previous value seen on the watched expression. */
  final oldValue;

  /** New value seen on the watched expression. */
  final newValue;

  /**
   * Change records for this object, or null. This property will be non-null
   * if [oldValue] and [newValue] are the same [Observable] object, but we
   * observed changes to the value itself.
   *
   * These records can be used for more efficient updates. For example if
   * updating a list of items, only new items can be rendered instead of
   * generating all of the content again.
   */
  final List<ChangeRecord> changes;

  ChangeNotification(this.oldValue, this.newValue, [this.changes]);

  // Note: these two methods are here mainly to make testing easier.
  bool operator ==(other) {
    return other is ChangeNotification && oldValue == other.oldValue &&
        newValue == other.newValue && changes == other.changes;
  }

  int get hashCode => hash3(oldValue, newValue, changes);

  String toString() {
    if (changes != null) return '#<ChangeNotification to $newValue: $changes>';
    return '#<ChangeNotification from $oldValue to $newValue>';
  }
}

/** Records a change to an [Observable]. */
class ChangeRecord {
  // Note: the target object is omitted because it makes it difficult
  // to proxy change records if you're using an observable type to aid
  // your implementation.
  // However: if we allow one observer to get batched changes for multiple
  // objects, we'll need to add target.

  // Note: type values were chosen for easy masking in the observable expression
  // implementation. However in [type] it will only have one value.

  /** [type] denoting set of a field. */
  static const FIELD = 1;

  // TODO(jmesserly): this is conceptually a remove+insert?
  /** [type] denoting an in-place update event using `[]=`. */
  static const INDEX = 2;

  /**
   * [type] denoting an insertion into a list. Insertions prepend in front of
   * the given index, so insert at 0 means an insertion at the beginning of the
   * list. The index will be provided in [name].
   */
  static const INSERT = INDEX | 4;

  /** [type] denoting a remove from a list. */
  static const REMOVE = INDEX | 8;

  /** Whether the change was a [FIELD], [INDEX], [INSERT], or [REMOVE]. */
  final int type;

  /**
   * The key that changed. The value depends on the [type] of change:
   *
   * - [FIELD]: the field name that was set.
   * - [INDEX], [INSERT], and [REMOVE]: the index or key that was changed.
   *   This will be an integer for [ObservableList] but can be anything for
   *   [ObservableMap] or [ObservableSet].
   */
  final key;

  /** The previous value of the member. */
  final oldValue;

  /** The new value of the member. */
  final newValue;

  ChangeRecord(this.type, this.key, this.oldValue, this.newValue);

  // Note: these two methods are here mainly to make testing easier.
  bool operator ==(other) {
    return other is ChangeRecord && type == other.type && key == other.key &&
        oldValue == other.oldValue && newValue == other.newValue;
  }

  int get hashCode => hash4(type, key, oldValue, newValue);

  String toString() {
    // TODO(jmesserly): const map would be nice here, but it must be string
    // literal :(
    String typeStr;
    switch (type) {
      case FIELD: typeStr = 'field'; break;
      case INDEX: typeStr = 'index'; break;
      case INSERT: typeStr = 'insert'; break;
      case REMOVE: typeStr = 'remove'; break;
    }
    return '#<ChangeRecord $typeStr $key from $oldValue to $newValue>';
  }
}

/**
 * Observes the value and delivers asynchronous notifications of changes
 * to the [callback].
 *
 * The [value] should be either an [ObservableExpression] or a [Observable].
 *
 * If the value is an expression, it is considered to have changed if the result
 * no longer compares equal via the equality operator. You can perform
 * additional comparisons in the [callback] if desired, using
 * [ChangeNotification.oldValue] and [ChangeNotification.newValue].
 *
 * If the value is [Observable] it will be observed, and considered to have
 * changed if any change is signaled. In this case the oldValue and newValue
 * will be the same. Use [observeChanges] instead if you want the list of
 * [ChangeRecord]s for that object.
 *
 * This returns a function that can be used to stop observation.
 * Calling this makes it possible for the garbage collector to reclaim memory
 * associated with the observation and prevents further calls to [callback].
 *
 * Because notifications are delivered asynchronously and batched, the callback
 * will only be run once for all changes that were made since the last time it
 * was run.
 *
 * You can force a synchronous change delivery at any time by calling
 * [deliverChangesSync]. Calling this method if there are no changes has no
 * effect. If changes are delivered by deliverChangesSync, they will not be
 * delivered again asynchronously, unless the value is changed again.
 *
 * Any errors thrown by [value] and [callback] will be caught and sent to
 * [onObserveUnhandledError].
 */
// TODO(jmesserly): debugName is here to workaround http://dartbug.com/8419.
ChangeUnobserver observe(value, ChangeObserver callback, [String debugName]) {

  // This is here mainly for symmetry.
  if (value is Observable) {
    Observable obs = value;
    return observeChanges(obs, (changes) {
      callback(new ChangeNotification(obs, obs, changes));
    });
  }

  var exprObserver = new _ExpressionObserver(value, callback, debugName);
  if (!exprObserver._observe()) {
    // If we didn't actually read anything, return a pointer to a no-op
    // function so the observer can be reclaimed immediately.
    return _doNothing;
  }

  return exprObserver._unobserve;
}

/**
 * Observes the object and delivers asynchronous notifications of changes
 * to the observer.
 *
 * Changes will be delivered when any field, index, or key changes its value.
 * The field is considered to have changed if the values no longer compare
 * equal via the equality operator.
 *
 * If you wish to observe a function, use [observe] instead.
 *
 * Returns a function that can be used to stop observation.
 * Calling this makes it possible for the garbage collector to reclaim memory
 * associated with the observation and prevents further calls to [observer].
 *
 * You can force a synchronous change delivery at any time by calling
 * [deliverChangesSync]. Calling this method if there are no changes has no
 * effect. If changes are delivered by deliverChangesSync, they will not be
 * delivered again asynchronously, unless the value is changed again.
 */
ChangeUnobserver observeChanges(Observable obj, ChangeRecordObserver observer) {
  if (obj.$_observers == null) obj.$_observers = new LinkedList();
  var node = obj.$_observers.add(observer);
  return node.remove;
}


/**
 * Converts the [Iterable], [Set] or [Map] to an [ObservableList],
 * [ObservableSet] or [ObservableMap] respectively.
 *
 * The resulting object will contain a shallow copy of the data.
 * If [value] is not one of those collection types, it will be returned
 * unmodified.
 *
 * If [value] is a [Map], the resulting value will use the appropriate kind of
 * backing map: either [HashMap], [LinkedHashMap], or [SplayTreeMap].
 */
toObservable(value) {
  if (value is Map) {
    var createMap = null;
    if (value is SplayTreeMap) {
      createMap = () => new SplayTreeMap();
    } else if (value is LinkedHashMap) {
      createMap = () => new LinkedHashMap();
    }
    return new ObservableMap.from(value, createMap: createMap);
  }
  if (value is Set) return new ObservableSet.from(value);
  if (value is Iterable) return new ObservableList.from(value);
  return value;
}

/**
 * An observable object. This is used by data in model-view architectures
 * to notify interested parties of changes.
 *
 * Most of the methods for observation are static methods to keep them
 * stratified from the objects being observed. This is a similar to the design
 * of Mirrors.
 */
class Observable {
  /** Observers for this object. Uses a linked-list for fast removal. */
  // TODO(jmesserly): make these fields private again once dart2js bugs around
  // mixins and private fields are fixed.
  // TODO(jmesserly): removed type annotation here to workaround a VM checked
  // mode bug. It should be: LinkedList<ChangeRecordObserver>
  var $_observers;

  /** Changes to this object since last batch was delivered. */
  List<ChangeRecord> $_changes;

  final int hashCode = ++Observable.$_nextHashCode;

  // TODO(jmessery): workaround for VM bug http://dartbug.com/5746
  // We need hashCode to be fast for _ExpressionObserver to work.
  static int $_nextHashCode = 0;
}

// Note: these are not instance methods of Observable, to make it clear that
// they aren't themselves being observed. It is the same reason that mirrors and
// EcmaScript's Object.observe are stratified.
// TODO(jmesserly): this makes it impossible to proxy an Observable. Is that an
// acceptable restriction?

/**
 * True if [self] has any observers, and should call [notifyChange] for
 * changes.
 *
 * Note: this is used by objects implementing [Observable].
 * You should not need it if your type is marked `@observable`.
 */
bool hasObservers(Observable self) =>
    self.$_observers != null && self.$_observers.head != null;

/**
 * True if we are observing reads. This should be checked before calling
 * [notifyRead].
 *
 * Note: this is used by objects implementing [Observable].
 * You should not need it if your type is marked `@observable`.
 */
bool get observeReads => _activeObserver != null;

/**
 * Notify that a [key] of [self] has been read. The key can also represent
 * a field or indexed value of an the object or list.
 *
 * Note: this is used by objects implementing [Observable].
 * You should not need it if your type is marked `@observable`.
 */
void notifyRead(Observable self, int type, key) =>
    _activeObserver._addRead(self, type, key);

/**
 * Notify that a [key] of [self] has been changed.
 *
 * The key can also represent a field or indexed value of the object or list.
 * The [type] is one of the constants [ChangeRecord.INDEX],
 * [ChangeRecord.FIELD], [ChangeRecord.INSERT], or [ChangeRecord.REMOVE].
 *
 * The [oldValue] and [newValue] are also recorded. If the change wasn't an
 * insert or remove, and the two values are equal, no change will be recorded.
 * For INSERT, oldValue should be null. For REMOVE, newValue should be null.
 *
 * Note: this is used by objects implementing [Observable].
 * You should not need it if your type is marked `@observable`.
 */
void notifyChange(Observable self, int type, key,
    Object oldValue, Object newValue) {

  // If this is an assignment (and not insert/remove) then check if
  // the value actually changed. If not don't signal a change event.
  // This helps programmers avoid some common cases of cycles in their code.
  if ((type & (ChangeRecord.INSERT | ChangeRecord.REMOVE)) == 0) {
    if (oldValue == newValue) return;
  }

  if (_changedObjects == null) {
    _changedObjects = [];
    setImmediate(deliverChangesSync);
  }
  if (self.$_changes == null) {
    self.$_changes = [];
    _changedObjects.add(self);
  }
  self.$_changes.add(new ChangeRecord(type, key, oldValue, newValue));
}

// Optimizations to avoid extra work if observing const/final data.
void _doNothing() {}

/**
 * The current observer that is tracking reads, or null if we aren't tracking
 * reads. Reads are tracked when executing [_ExpressionObserver._observe].
 */
_ExpressionObserver _activeObserver;

/**
 * The limit of times we will attempt to deliver a set of pending changes.
 *
 * [deliverChangesSync] will attempt to deliver pending changes until there are
 * no more. If one of the pending changes causes another batch of changes, it
 * will iterate again and increment the iteration counter. Once it reaches
 * this limit it will call [onCircularNotifyLimit].
 *
 * Note that there is no limit to the number of changes per batch, only to the
 * number of iterations.
 */
int circularNotifyLimit = 100;

/** The per-isolate list of changed objects. */
List<Observable> _changedObjects;

// Note: we keep pending expression observers sorted by order of creation.
// TODO(jmesserly): this is here to help our template system, which relies
// on earlier observers removing later ones to prevent them from firing.
// See if we can find a better solution at the template level.
/** The per-isolate list of possibly changed expressions. */
SplayTreeMap<num, _ExpressionObserver> _changedExpressions;

/**
 * Delivers observed changes immediately. Normally you should not call this
 * directly, but it can be used to force synchronous delivery, which helps in
 * certain cases like testing.
 *
 * Note: this will continue delivering changes as long as some are pending and
 * [circularNotifyLimit] has not been reached.
 */
void deliverChangesSync() {
  int iterations = 0;
  while (_changedObjects != null || _changedExpressions != null) {
    var changedObjects = _changedObjects;
    _changedObjects = null;

    var changedExpressions = _changedExpressions;
    _changedExpressions = null;

    if (iterations++ == circularNotifyLimit) {
      _diagnoseCircularLimit(changedObjects, changedExpressions);
      return;
    }

    if (changedObjects != null) {
      for (var observable in changedObjects) {
        // TODO(jmesserly): freeze the "changes" list?
        // If one observer incorrectly mutates it, it will affect what future
        // observers see, possibly leading to subtle bugs.
        // OTOH, I don't want to add a defensive copy here. Maybe a wrapper that
        // prevents mutation, or a ListBuilder of some sort than can be frozen.
        var changes = observable.$_changes;
        observable.$_changes = null;

        for (var n = observable.$_observers.head; n != null; n = n.next) {
          var observer = n.value;
          try {
            observer(changes);
          } catch (error, trace) {
            onObserveUnhandledError(error, trace, observer, 'from $observable');
          }
        }
      }
    }

    if (changedExpressions != null) {
      // TODO(jmesserly): we are avoiding SplayTreeMap.values because it
      // performs an unnecessary copy. If that gets fixed we can use .values.
      // https://code.google.com/p/dart/issues/detail?id=8516
      changedExpressions.forEach((id, obs) { obs._deliver(); });
    }
  }
}


/**
 * Attempt to provide diagnostics about what change is causing a loop in
 * observers. Unfortunately it is hard to help the programmer unless they have
 * provided a `debugName` to [observe], as callbacks are hard to debug
 * because of <http://dartbug.com/8419>. However we can print the records that
 * changed which has proved helpful.
 */
void _diagnoseCircularLimit(List<Observable> changedObjects,
    Map<int, _ExpressionObserver> changedExpressions) {
  // TODO(jmesserly,sigmund): we could do purity checks when running "observe"
  // itself, to detect if it causes writes to happen. I think that case is less
  // common than cycles caused by the notifications though.

  var trace = [];
  if (changedObjects != null) {
    for (var observable in changedObjects) {
      var changes = observable.$_changes;
      trace.add('$observable $changes');
    }
  }

  if (changedExpressions != null) {
    for (var exprObserver in changedExpressions.values) {
      var change = exprObserver._deliver();
      if (change != null) trace.add('$exprObserver $change');
    }
  }

  // Throw away pending changes to prevent repeating this error.
  _changedObjects = null;
  _changedExpressions = null;

  var msg = 'exceeded notifiction limit of $circularNotifyLimit, possible '
      'circular reference in observer callbacks: ${trace.take(10).join(", ")}';

  onCircularNotifyLimit(msg);
}


class _ExpressionObserver {
  static int _nextId = 0;

  /**
   * The ID indicating creation order. We will call observers in ID order.
   * See the TODO in [deliverChangesSync].
   */
  final int _id = ++_ExpressionObserver._nextId;

  final ObservableExpression _expression;

  final ChangeObserver _callback;

  /**
   * The name used for debugging. This will be removed once Dart has
   * better debugging of callbacks.
   */
  final String _debugName;

  // TODO(jmesserly): ideally this would be an identity map.
  final Map<Observable, Map<Object, int>> _reads = new Map();

  final List<ChangeUnobserver> _unobservers = [];

  bool _scheduled = false;

  /** The last value of this observable. */
  Object _value;

  _ExpressionObserver(this._expression, this._callback, this._debugName);

  /** True if this observer has been unobserved. */
  // Note: any time we call out to user-provided code, they might call
  // unobserve, so we need to guard against that.
  bool get _dead => _callback == null;

  String toString() =>
      _debugName != null ? '<observer $_id: $_debugName>' : '<observer $_id>';

  bool _observe() {
    // If an observe call starts another observation, we need to make sure that
    // the outer observe is tracked correctly.
    var parent = _activeObserver;
    _activeObserver = this;
    try {
      _value = _expression();
      // TODO(jmesserly): not sure if this belongs here. Iterables are tricky.
      // Because of their lazy nature it's easy to use them incorrectly in
      // expression observers. By forcing eager evaluation we avoid
      // those problems. Another alternative would be to have Observable
      // iterators that forward messages from the original collection, but that
      // is difficult implement (and would have too much overhead because of
      // how observeChanges is stratified).
      if (_value is Iterable && _value is! List && _value is! Observable) {
        _value = (_value as Iterable).toList();
      }
    } catch (e, trace) {
      onObserveUnhandledError(e, trace, _expression, 'from $this');
      _value = null;
    }

    _reads.forEach(_watchForChange);
    _reads.clear();

    // TODO(jmesserly): should we add our changes to the parent?
    assert(_activeObserver == this);
    _activeObserver = parent;

    _observeValue();

    // Return true if we are actually observing something.
    return _unobservers.length > 0;
  }

  void _runCallback(ChangeNotification change) {
    try {
      _callback(change);
    } catch (e, trace) {
      onObserveUnhandledError(e, trace, _callback, 'from $this');
    }
  }

  // Observes the result value if it is Observable.
  void _observeValue() {
    var value = _value;
    if (value is! Observable) return;

    _unobservers.add(observeChanges(value, (changes) {
      _runCallback(new ChangeNotification(value, value, changes));
    }));
  }

  void _addRead(Observable target, int type, key) {
    var reads = _reads.putIfAbsent(target, () => new Map());
    // TODO(jmesserly): here we rely on "key" having a good hash implementation.

    try {
      int mask = reads[key];
      // Use a mask so we can easily match against the type.
      if (mask == null) mask = 0;
      reads[key] = mask | type;
    } catch (e, trace) {
      onObserveUnhandledError(e, trace, key,
          'hashCode or operator == from $this');
    }
  }

  void _watchForChange(Observable target, Map<Object, int> reads) {
    _unobservers.add(observeChanges(target, (changes) {
      if (_scheduled) return;
      for (var change in changes) {
        int mask = reads[change.key];
        if (mask != null && (mask & change.type) != 0) {
          _scheduled = true;
          if (_changedExpressions == null) {
            _changedExpressions = new SplayTreeMap();
          }
          _changedExpressions[_id] = this;
          return;
        }
      }
    }));
  }

  void _unobserve() {
    for (var unobserver in _unobservers) {
      unobserver();
    }
    _scheduled = false;
  }

  // _deliver does two things:
  // 1. Evaluate the expression to compute the new value.
  // 2. Invoke observer for this expression.
  //
  // Note: if you mutate a shared value from one observer, future
  // observers will see the updated value. Essentially, we collapse
  // the two change notifications into one.
  //
  // We could try someting else, but the current order has benefits:
  // it preserves the invariant that ExpressionChange.newValue equals the
  // current value of the expression.
  ChangeNotification _deliver() {
    if (!_scheduled) return null;

    var oldValue = _value;

    // Call the expression again to compute the new value, and to get the new
    // list of dependencies.
    _unobserve();
    _observe();

    try {
      if (oldValue == _value) return null;
    } catch (e, trace) {
      onObserveUnhandledError(e, trace, oldValue, 'operator == from $this');
      return null;
    }

    var change = new ChangeNotification(oldValue, _value);
    _runCallback(change);
    return change;
  }
}


typedef void CircularNotifyLimitHandler(String message);

/**
 * Function that is called when change notifications get stuck in a circular
 * loop, which can happen if one [ChangeObserver] causes another change to
 * happen, and that change causes another, etc.
 *
 * This is called when [circularNotifyLimit] is reached by
 * [deliverChangesSync]. Circular references are commonly the result of not
 * correctly implementing equality for objects.
 *
 * The default behavior is to print the message.
 */
// TODO(jmesserly): using Logger seems better, but by default it doesn't do
// anything, which leads to unobserved errors.
CircularNotifyLimitHandler onCircularNotifyLimit = (message) => print(message);

/**
 * A function that handles an [error] given the [stackTrace] that caused the
 * error. The other arguments provide additional context about the error.
 */
typedef void ObserverErrorHandler(error, stackTrace, obj, String message);

/**
 * Callback to intercept unhandled errors in evaluating an observable.
 * Includes the error, stack trace, and information about what caused the error.
 * By default it will use [defaultObserveUnhandledError], which prints the
 * error.
 */
ObserverErrorHandler onObserveUnhandledError = defaultObserveUnhandledError;

/** The default handler for [onObserveUnhandledError]. Prints the error. */
void defaultObserveUnhandledError(error, trace, obj, String message) {
  // TODO(jmesserly): using Logger seems better, but by default it doesn't do
  // anything, which leads to unobserved errors.
  // Ideally we could make this show up as an error in the browser's console.
  print('web_ui.observe: unhandled error calling $obj $message.\n'
      'error:\n$error\n\nstack trace:\n$trace');
}

/**
 * The type of the `@observable` annotation.
 *
 * Library private because you should be able to use the [observable] field
 * to get the one and only instance. We could make it public though, if anyone
 * needs it for some reason.
 */
class _ObservableAnnotation {
  const _ObservableAnnotation();
}
