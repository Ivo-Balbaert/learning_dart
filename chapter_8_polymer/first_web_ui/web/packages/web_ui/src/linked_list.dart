// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A doubly-linked list, adapted from DoubleLinkedQueueEntry in
 * sdk/lib/collection/queue.dart.
 */
// TODO(jmesserly): this should be in a shared pkg somewhere. Surely I am not
// the only person who will want to use a linked list :)
library linked_list;

import 'dart:collection' hide LinkedList, LinkedListEntry;

/**
 * An entry in a doubly linked list. It contains a pointer to the next
 * entry, the previous entry, and the boxed value.
 */
class LinkedListNode<E> {
  LinkedListNode<E> _previous;
  LinkedListNode<E> _next;
  LinkedList<E> _list;
  E _value;

  LinkedListNode._(E value, this._list) : _value = value {
    if (_list != null) _list._length++;
  }

  LinkedListNode<E> get previous => _previous;

  LinkedListNode<E> get next => _next;

  E get value => _value;

  set value(E e) => _value = e;

  LinkedListNode<E> _link(LinkedListNode<E> p, LinkedListNode<E> n) {
    _next = n;
    _previous = p;
    if (p != null) p._next = this;
    if (n != null) n._previous = this;
    return this;
  }

  LinkedListNode<E> append(E e) =>
      new LinkedListNode<E>._(e, _list)._link(this, _next);

  LinkedListNode<E> prepend(E e) =>
      new LinkedListNode<E>._(e, _list)._link(_previous, this);

  void remove() {
    if (_list == null) return;

    _list._length--;
    if (_previous != null) {
      _previous._next = _next;
    } else {
      _list._head = _next;
    }
    if (_next != null) {
      _next._previous = _previous;
    } else {
      _list._tail = _previous;
    }
    _next = null;
    _previous = null;
    _list = null;
  }
}


class LinkedList<E> extends IterableBase<E> {
  LinkedListNode<E> _head;
  LinkedListNode<E> _tail;

  int get length => _length;
  int _length = 0;

  LinkedList() {}

  LinkedListNode<E> get head => _head;

  LinkedListNode<E> get tail => _tail;

  LinkedListNode<E> add(E e) {
    var node = new LinkedListNode<E>._(e, this);
    if (_tail == null) return _head = _tail = node;
    return _tail = node._link(_tail, null);
  }

  LinkedListNode<E> addLast(E e) => add(e);

  LinkedListNode<E> addFirst(E e) {
    var node = new LinkedListNode<E>._(e, this);
    if (_head == null) return _head = _tail = node;
    return _head = node._link(null, _head);
  }

  void addAll(Iterable<E> e) => e.forEach(add);

  Iterator<E> get iterator => new LinkedListIterator<E>(this);
}

class LinkedListIterator<E> implements Iterator<E> {
  // Use a copy to support mutations where the current node, as well as any
  // number of subsequent nodes are removed.
  List<LinkedListNode<E>> _copy;
  LinkedList<E> _list;
  E _current;
  int _pos = -1;

  LinkedListIterator(this._list) {
    // TODO(jmesserly): removed type annotation here to work around
    // http://dartbug.com/9050.
    _copy = new List<LinkedListNode>(_list.length);
    int i = 0;
    var node = _list.head;
    while (node != null) {
      _copy[i++] = node;
      node = node.next;
    }
  }

  E get current => _current;

  bool moveNext() {
    do {
      _pos++;
      // Skip nodes that no longer are part of the list.
    } while (_pos < _copy.length && _copy[_pos]._list != _list);

    if (_pos < _copy.length) {
      _current = _copy[_pos].value;
      return true;
    } else {
      _current = null;
      return false;
    }
  }
}
