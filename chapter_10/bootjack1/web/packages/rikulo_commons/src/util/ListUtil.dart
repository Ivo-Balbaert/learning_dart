//Copyright (C) 2012 Potix Corporation. All Rights Reserved.
//History: Tue, Jun 05, 2012  9:16:58 AM
// Author: tomyeh
part of rikulo_util;

/** A readonly and empty list.
 */
const List EMPTY_LIST = const [];
/** A readonly and empty iterator.
 */
const Iterator EMPTY_ITERATOR = const _EmptyIter();

class _EmptyIter<T> implements Iterator<T> {
  const _EmptyIter();

  @override
  T get current => null;
  @override
  bool moveNext() => false;
}

/** List utilities.
 */
class ListUtil {
  ///Copy a list ([src]) to another ([dst])
  static List copy(List src, int srcStart,
                   List dst, int dstStart, int count) {
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
    return dst;
  }

  /** Compares if a list equals another
   *
	 * Notice that it compares each item in the list with `identical()`.
   */
  static bool areEqual(List a, Object b) {
    if (identical(a, b)) return true;
    if (!(b is List)) return false;

    final bl = b as List,
    	length = a.length;
    if (length != bl.length) return false;

    for (int i = 0; i < length; i++) {
      if (!identical(a[i], bl[i])) return false;
    }
    return true;
  }
}