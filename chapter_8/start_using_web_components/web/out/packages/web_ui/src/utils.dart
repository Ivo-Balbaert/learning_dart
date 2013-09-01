// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library web_ui.src.utils;

import 'dart:async';

import 'package:pathos/path.dart' show Builder;


/**
 * An instance of the pathos library builder. We could just use the default
 * builder in pathos, but we add this indirection to make it possible to run
 * unittest for windows paths.
 */
Builder path = new Builder();

/** Convert a OS specific path into a url. */
String pathToUrl(String relPath) =>
  (path.separator == '/') ? relPath : path.split(relPath).join('/');

/**
 * Converts a string name with hyphens into an identifier, by removing hyphens
 * and capitalizing the following letter. Optionally [startUppercase] to
 * captialize the first letter.
 */
String toCamelCase(String hyphenedName, {bool startUppercase: false}) {
  var segments = hyphenedName.split('-');
  int start = startUppercase ? 0 : 1;
  for (int i = start; i < segments.length; i++) {
    var segment = segments[i];
    if (segment.length > 0) {
      // Character between 'a'..'z' mapped to 'A'..'Z'
      segments[i] = '${segment[0].toUpperCase()}${segment.substring(1)}';
    }
  }
  return segments.join('');
}

/**
 * Invokes [callback], logs how long it took to execute in ms, and returns
 * whatever [callback] returns. The log message will be printed if [printTime]
 * is true.
 */
time(String logMessage, callback(),
     {bool printTime: false, bool useColors: false}) {
  final watch = new Stopwatch();
  watch.start();
  var result = callback();
  watch.stop();
  final duration = watch.elapsedMilliseconds;
  if (printTime) {
    _printMessage(logMessage, duration, useColors);
  }
  return result;
}

/**
 * Invokes [callback], logs how long it takes from the moment [callback] is
 * executed until the future it returns is completed. Returns the future
 * returned by [callback]. The log message will be printed if [printTime]
 * is true.
 */
Future asyncTime(String logMessage, Future callback(),
                 {bool printTime: false, bool useColors: false}) {
  final watch = new Stopwatch();
  watch.start();
  return callback()..then((_) {
    watch.stop();
    final duration = watch.elapsedMilliseconds;
    if (printTime) {
      _printMessage(logMessage, duration, useColors);
    }
  });
}

void _printMessage(String logMessage, int duration, bool useColors) {
  var buf = new StringBuffer();
  buf.write(logMessage);
  for (int i = logMessage.length; i < 60; i++) buf.write(' ');
  buf.write(' -- ');
  if (useColors) {
    buf.write(GREEN_COLOR);
  }
  if (duration < 10) buf.write(' ');
  if (duration < 100) buf.write(' ');
  buf..write(duration)..write(' ms');
  if (useColors) {
    buf.write(NO_COLOR);
  }
  print(buf.toString());
}

// Color constants used for generating messages.
final String GREEN_COLOR = '\u001b[32m';
final String RED_COLOR = '\u001b[31m';
final String MAGENTA_COLOR = '\u001b[35m';
final String NO_COLOR = '\u001b[0m';

/** Find and return the first element in [list] that satisfies [matcher]. */
find(List list, bool matcher(elem)) {
  for (var elem in list) {
    if (matcher(elem)) return elem;
  }
  return null;
}


/** A future that waits until all added [Future]s complete. */
// TODO(sigmund): this should be part of the futures/core libraries.
class FutureGroup {
  static const _FINISHED = -1;

  int _pending = 0;
  Future _failedTask;
  final Completer<List> _completer = new Completer<List>();
  final List results = [];

  /** Gets the task that failed, if any. */
  Future get failedTask => _failedTask;

  /**
   * Wait for [task] to complete.
   *
   * If this group has already been marked as completed, you'll get a
   * [StateError].
   *
   * If this group has a [failedTask], new tasks will be ignored, because the
   * error has already been signaled.
   */
  void add(Future task) {
    if (_failedTask != null) return;
    if (_pending == _FINISHED) throw new StateError("Future already completed");

    _pending++;
    var i = results.length;
    results.add(null);
    task.then((res) {
      results[i] = res;
      if (_failedTask != null) return;
      _pending--;
      if (_pending == 0) {
        _pending = _FINISHED;
        _completer.complete(results);
      }
    }, onError: (e) {
      if (_failedTask != null) return;
      _failedTask = task;
      _completer.completeError(e, getAttachedStackTrace(e));
    });
  }

  Future<List> get future => _completer.future;
}


/**
 * Escapes [text] for use in a Dart string.
 * [single] specifies single quote `'` vs double quote `"`.
 * [triple] indicates that a triple-quoted string, such as `'''` or `"""`.
 */
String escapeDartString(String text, {bool single: true, bool triple: false}) {
  // Note: don't allocate anything until we know we need it.
  StringBuffer result = null;

  for (int i = 0; i < text.length; i++) {
    int code = text.codeUnitAt(i);
    var replace = null;
    switch (code) {
      case 92/*'\\'*/: replace = r'\\'; break;
      case 36/*r'$'*/: replace = r'\$'; break;
      case 34/*'"'*/:  if (!single) replace = r'\"'; break;
      case 39/*"'"*/:  if (single) replace = r"\'"; break;
      case 10/*'\n'*/: if (!triple) replace = r'\n'; break;
      case 13/*'\r'*/: if (!triple) replace = r'\r'; break;

      // Note: we don't escape unicode characters, under the assumption that
      // writing the file in UTF-8 will take care of this.

      // TODO(jmesserly): do we want to replace any other non-printable
      // characters (such as \f) for readability?
    }

    if (replace != null && result == null) {
      result = new StringBuffer(text.substring(0, i));
    }

    if (result != null) result.write(replace != null ? replace : text[i]);
  }

  return result == null ? text : result.toString();
}

const int _LF = 10;
bool _isWhitespace(int charCode) {
  switch (charCode) {
    case 9:  // '\t'
    case _LF: // '\n'
    case 12: // '\f'
    case 13: // '\r'
    case 32: // ' '
      return true;
  }
  return false;
}


/**
 * Trims or compacts the leading/trailing white spaces of [text]. If the leading
 * spaces contain no line breaks, then all spaces are merged into a single
 * space. Similarly, for trailing spaces. These are examples of what this
 * function would return on a given input:
 *
 *       trimOrCompact('  x  ')          => ' x '
 *       trimOrCompact('\n\n  x  \n')    => 'x'
 *       trimOrCompact('\n\n  x       ') => 'x '
 *       trimOrCompact('\n\n  ')         => ''
 *       trimOrCompact('      ')         => ' '
 *       trimOrCompact(' \nx ')          => ' x '
 *       trimOrCompact('  x\n ')         => ' x'
 */
String trimOrCompact(String text) {
  int first = 0;
  int len = text.length;
  int last = len - 1;
  bool hasLineBreak = false;

  while (first < len) {
    var ch = text.codeUnitAt(first);
    if (!_isWhitespace(ch)) break;
    if (ch == _LF) hasLineBreak = true;
    first++;
  }

  // If we just have spaces, return either an empty string or a single space
  if (first > last) return hasLineBreak || text.isEmpty ? '' : ' ';

  // Include a space in the output if there was a line break.
  if (first > 0 && !hasLineBreak) first--;

  hasLineBreak = false;
  while (last > 0) {
    var ch = text.codeUnitAt(last);
    if (!_isWhitespace(ch)) break;
    if (ch == _LF) hasLineBreak = true;
    last--;
  }

  if (last < len - 1 && !hasLineBreak) last++;
  if (first == 0 && last == len - 1) return text;
  return text.substring(first, last + 1);
}

/** Iterates through an infinite sequence, starting from zero. */
class IntIterator implements Iterator<int> {
  int _next = -1;

  int get current => _next < 0 ? null : _next;

  bool moveNext() {
    _next++;
    return true;
  }
}


// TODO(jmesserly): VM hashCode performance workaround.
// https://code.google.com/p/dart/issues/detail?id=5746
class Hashable {
  static int _nextHash = 0;
  final int hashCode = ++_nextHash;
}


/**
 * Asserts that the condition is true, if not throws an [InternalError].
 * Note: unlike "assert" we want these errors to be always on so we get bug
 * reports.
 */
void compilerAssert(bool condition, [String message]) {
  if (!condition) throw new InternalError(message);
}

// TODO(jmesserly): this is a start, but what we might want to instead: catch
// all errors at the top level and log to message (including stack). That way if
// we have a noSuchMethod error or something it will show up the same way as
// this does, including the bug report link.
/** Error thrown if there is a bug in the compiler itself. */
class InternalError implements Error {
  final message;

  InternalError([this.message]);

  String toString() {
    var additionalMessage = '';
    if (message != null) {
      additionalMessage = '\nInternal message: $message';
    }
    return "We're sorry, you've just found a compiler bug. "
      'You can report it at:\n'
      'https://github.com/dart-lang/web-ui/issues/new\n'
      'Thanks in advance for the bug report! It will help us improve Web UI.'
      '$additionalMessage';
  }
}
