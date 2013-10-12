// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library frame;


import 'package:path/path.dart' as path;

import 'trace.dart';

// #1      Foo._bar (file:///home/nweiz/code/stuff.dart:42:21)
final _vmFrame = new RegExp(
    r'^#\d+\s+([^\s].*) \((.+?):(\d+)(?::(\d+))?\)$');

//     at VW.call$0 (http://pub.dartlang.org/stuff.dart.js:560:28)
//     at http://pub.dartlang.org/stuff.dart.js:560:28
final _v8Frame = new RegExp(
    r'^\s*at (?:([^\s].*?)(?: \[as [^\]]+\])? '
    r'\((.+):(\d+):(\d+)\)|(.+):(\d+):(\d+))$');

// .VW.call$0@http://pub.dartlang.org/stuff.dart.js:560
// .VW.call$0("arg")@http://pub.dartlang.org/stuff.dart.js:560
// .VW.call$0/name<@http://pub.dartlang.org/stuff.dart.js:560
final _firefoxFrame = new RegExp(
    r'^([^@(/]*)(?:\(.*\))?(/[^<]*<?)?(?:\(.*\))?@(.*):(\d+)$');

// foo/bar.dart 10:11 in Foo._bar
// http://dartlang.org/foo/bar.dart in Foo._bar
final _friendlyFrame = new RegExp(
    r'^([^\s]+)(?: (\d+):(\d+))?\s+([^\d][^\s]*)$');

final _initialDot = new RegExp(r"^\.");

/// A single stack frame. Each frame points to a precise location in Dart code.
class Frame {
  /// The URI of the file in which the code is located.
  ///
  /// This URI will usually have the scheme `dart`, `file`, `http`, or `https`.
  final Uri uri;

  /// The line number on which the code location is located.
  ///
  /// This can be null, indicating that the line number is unknown or
  /// unimportant.
  final int line;

  /// The column number of the code location.
  ///
  /// This can be null, indicating that the column number is unknown or
  /// unimportant.
  final int column;

  /// The name of the member in which the code location occurs.
  ///
  /// Anonymous closures are represented as `<fn>` in this member string.
  final String member;

  /// Whether this stack frame comes from the Dart core libraries.
  bool get isCore => uri.scheme == 'dart';

  /// Returns a human-friendly description of the library that this stack frame
  /// comes from.
  ///
  /// This will usually be the string form of [uri], but a relative URI will be
  /// used if possible.
  String get library {
    if (uri.scheme != 'file') return uri.toString();
    return path.relative(path.fromUri(uri));
  }

  /// Returns the name of the package this stack frame comes from, or `null` if
  /// this stack frame doesn't come from a `package:` URL.
  String get package {
    if (uri.scheme != 'package') return null;
    return uri.path.split('/').first;
  }

  /// A human-friendly description of the code location.
  String get location {
    if (line == null || column == null) return library;
    return '$library $line:$column';
  }

  /// Returns a single frame of the current stack.
  ///
  /// By default, this will return the frame above the current method. If
  /// [level] is `0`, it will return the current method's frame; if [level] is
  /// higher than `1`, it will return higher frames.
  factory Frame.caller([int level=1]) {
    if (level < 0) {
      throw new ArgumentError("Argument [level] must be greater than or equal "
          "to 0.");
    }

    return new Trace.current(level + 1).frames.first;
  }

  /// Parses a string representation of a Dart VM stack frame.
  factory Frame.parseVM(String frame) {
    // The VM sometimes folds multiple stack frames together and replaces them
    // with "...".
    if (frame == '...') {
      return new Frame(new Uri(), null, null, '...');
    }

    var match = _vmFrame.firstMatch(frame);
    if (match == null) {
      throw new FormatException("Couldn't parse VM stack trace line '$frame'.");
    }

    // Get the pieces out of the regexp match. Function, URI and line should
    // always be found. The column is optional.
    var member = match[1].replaceAll("<anonymous closure>", "<fn>");
    var uri = Uri.parse(match[2]);
    var line = int.parse(match[3]);
    var column = null;
    var columnMatch = match[4];
    if (columnMatch != null) {
      column = int.parse(columnMatch);
    }
    return new Frame(uri, line, column, member);
  }

  /// Parses a string representation of a Chrome/V8 stack frame.
  factory Frame.parseV8(String frame) {
    var match = _v8Frame.firstMatch(frame);
    if (match == null) {
      throw new FormatException("Couldn't parse V8 stack trace line '$frame'.");
    }

    // V8 stack frames can be in two forms.
    if (match[2] != null) {
      // The first form looks like "  at FUNCTION (URI:LINE:COL)"
      var uri = Uri.parse(match[2]);
      var member = match[1].replaceAll("<anonymous>", "<fn>");
      return new Frame(uri, int.parse(match[3]), int.parse(match[4]), member);
    } else {
      // The second form looks like " at URI:LINE:COL", and is used for
      // anonymous functions.
      var uri = Uri.parse(match[5]);
      return new Frame(uri, int.parse(match[6]), int.parse(match[7]), "<fn>");
    }
  }

  /// Parses a string representation of an IE stack frame.
  ///
  /// IE10+ frames look just like V8 frames. Prior to IE10, stack traces can't
  /// be retrieved.
  factory Frame.parseIE(String frame) => new Frame.parseV8(frame);

  /// Parses a string representation of a Firefox stack frame.
  factory Frame.parseFirefox(String frame) {
    var match = _firefoxFrame.firstMatch(frame);
    if (match == null) {
      throw new FormatException(
          "Couldn't parse Firefox stack trace line '$frame'.");
    }

    var uri = Uri.parse(match[3]);
    var member = match[1];
    if (member == "") {
      member = "<fn>";
    } else if (match[2] != null) {
      member = "$member.<fn>";
    }
    // Some Firefox members have initial dots. We remove them for consistency
    // with other platforms.
    member = member.replaceFirst(_initialDot, '');
    return new Frame(uri, int.parse(match[4]), null, member);
  }

  /// Parses a string representation of a Safari stack frame.
  ///
  /// Safari 6+ frames look just like Firefox frames. Prior to Safari 6, stack
  /// traces can't be retrieved.
  factory Frame.parseSafari(String frame) => new Frame.parseFirefox(frame);

  /// Parses this package's string representation of a stack frame.
  factory Frame.parseFriendly(String frame) {
    var match = _friendlyFrame.firstMatch(frame);
    if (match == null) {
      throw new FormatException(
          "Couldn't parse package:stack_trace stack trace line '$frame'.");
    }

    var uri = Uri.parse(match[1]);
    // If there's no scheme, this is a relative URI. We should interpret it as
    // relative to the current working directory.
    if (uri.scheme == '') {
      uri = path.toUri(path.absolute(path.fromUri(uri)));
    }

    var line = match[2] == null ? null : int.parse(match[2]);
    var column = match[3] == null ? null : int.parse(match[3]);
    return new Frame(uri, line, column, match[4]);
  }

  Frame(this.uri, this.line, this.column, this.member);

  String toString() => '$location in $member';
}
