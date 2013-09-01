// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_printer;

import 'dart:utf' show stringToCodepoints;
import 'package:source_maps/source_maps.dart';

/**
 * Helper class to format generated code and keep track of source map
 * information.
 */
class CodePrinter {

  /**
   * Items recoded by this printer, which can be [String] literals,
   * other printing helpers such as [Declarations] and [CodePrinter],
   * and source map information like [Location] and [Span].
   */
  List _items = [];

  /** Internal buffer to merge consecutive strings added to this printer. */
  StringBuffer _buff;

  /** Current indentation, which can be updated from outside this class. */
  int indent = 0;

  /**
   * Item used to indicate that the following item is copied from the original
   * source code, and hence we should preserve source-maps on every new line.
   */
  static final _ORIGINAL = new Object();

  CodePrinter(this.indent);

  /**
   * Adds [object] to this printer. [object] can be a [String], [Declarations],
   * or a [CodePrinter]. If [object] is a [String], the value is appended
   * directly, without doing any formatting changes. If you wish to add a line
   * of code with automatic indentation, use [addLine] instead. [Declarations]
   * and [CodePrinter] are not processed until [build] gets called later on.
   * We ensure that [build] emits every object in the order that they were added
   * to this printer.
   *
   * The [location] and [span] parameters indicate the corresponding source map
   * location of [object] in the original input. Only one, [location] or
   * [span], should be provided at a time.
   *
   * Indicate [isOriginal] when [object] is copied directly from the user code.
   * Setting [isOriginal] will make this printer propagate source map locations
   * on every line-break.
   */
  void add(object, {Location location, Span span, bool isOriginal: false}) {
    if (object is! String || location != null || span != null || isOriginal) {
      _flush();
      assert(location == null || span == null);
      if (location != null) _items.add(location);
      if (span != null) _items.add(span);
      if (isOriginal) _items.add(_ORIGINAL);
    }

    if (object is String) {
      _appendString(object);
    } else {
      _items.add(object);
    }
  }

  /** Append `2 * indent` spaces to this printer. */
  void insertIndent() => _indent(indent);

  /**
   * Add a [line], autoindenting to the current value of [indent]. Note,
   * indentation is not inferred, so if a line opens or closes an indentation
   * block, you need to also update [indent] accordingly. Also, indentation is
   * not adapted for nested code printers. If you add a [CodePrinter] to this
   * printer, its indentation is set separately and will not include any
   * the indentation set here.
   *
   * The [location] and [span] parameters indicate the corresponding source map
   * location of [object] in the original input. Only one, [location] or
   * [span], should be provided at a time.
   */
  void addLine(String line, {Location location, Span span}) {
    if (location != null || span != null) {
      _flush();
      assert(location == null || span == null);
      if (location != null) _items.add(location);
      if (span != null) _items.add(span);
    }
    if (line == null) return;
    if (line != '') {
      // We don't indent empty lines.
      _indent(indent);
      _appendString(line);
    }
    _appendString('\n');
  }

  /** Appends a string merging it with any previous strings, if possible. */
  void _appendString(String s) {
    if (_buff == null) _buff = new StringBuffer();
    _buff.write(s);
  }

  /** Adds all of the current [_buff] contents as a string item. */
  void _flush() {
    if (_buff != null) {
      _items.add(_buff.toString());
      _buff = null;
    }
  }

  void _indent(int indent) {
    for (int i = 0; i < indent; i++) _appendString('  ');
  }

  /**
   * Returns a string representation of all the contents appended to this
   * printer, including source map location tokens.
   */
  String toString() {
    _flush();
    return (new StringBuffer()..writeAll(_items)).toString();
  }

  /** [Printer] used during the last call to [build], if any. */
  Printer _printer;

  /** Returns the text produced after calling [build]. */
  String get text => _printer.text;

  /** Returns the source-map information produced after calling [build]. */
  String get map => _printer.map;

  /**
   * Builds the output of this printer and source map information. After calling
   * this function, you can use [text] and [map] to retrieve the geenrated code
   * and source map information, respectively.
   */
  void build(String filename) {
    _build(_printer = new Printer(filename));
  }

  void _build(Printer printer) {
    _flush();
    bool propagate = false;
    for (var item in _items) {
      if (item is Declarations) {
        item._build(printer);
      } else if (item is CodePrinter) {
        item._build(printer);
      } else if (item is String) {
        printer.add(item, projectMarks: propagate);
        propagate = false;
      } else if (item is Location || item is Span) {
        printer.mark(item);
      } else if (item == _ORIGINAL) {
        // we insert booleans when we are about to quote text that was copied
        // from the original source. In such case, we will propagate marks on
        // every new-line.
        propagate = true;
      } else {
        throw new UnsupportedError('Unknown item type: $item');
      }
    }
  }
}

/** A declaration of a field or local variable. */
class Declaration implements Comparable {
  final String type;
  final String name;
  final Span sourceSpan;
  final String initializer;

  Declaration(this.type, this.name, this.sourceSpan, [this.initializer]);

  /**
   * Sort declarations by type, so they can be merged together in a declaration
   * group.
   */
  int compareTo(Declaration other) {
    if (type != other.type) return type.compareTo(other.type);
    return name.compareTo(other.name);
  }
}

/** A set of declarations grouped together. */
class Declarations {

  /** All declarations in this group. */
  final List<Declaration> declarations = <Declaration>[];

  /** Indentation associated with this declaration group. */
  final int indent;

  /** Whether these declarations are local variables or fields in a class. */
  final bool isLocal;

  /** Whether types should be prefixed with the "static" keyword. */
  final bool staticKeyword;

  Declarations(this.indent, {this.isLocal: false, this.staticKeyword: false});

  /** Add a declaration to this group. */
  void add(String type, String identifier, Span sourceSpan, [String init]) {
    declarations.add(
        new Declaration(isLocal ? 'var' : type, identifier, sourceSpan, init));
  }

  String toString() {
    var printer = new Printer(null);
    _build(printer);
    return printer.text;
  }

  void _build(Printer printer) {
    if (declarations.length == 0) return;
    declarations.sort();
    var lastType = null;
    printer.addSpaces(2 * indent);
    for (var d in declarations) {
      if (d.type != lastType) {
        if (lastType != null) {
          printer.add(';\n');
          printer.addSpaces(2 * indent);
        }
        if (staticKeyword) printer.add('static ');
        printer.add(d.type);
        lastType = d.type;
      } else {
        printer.add(',');
      }
      printer.add(' ');
      if (d.sourceSpan != null) printer.mark(d.sourceSpan);
      printer.add(d.name);
      if (d.initializer != null) {
        printer..add(' = ')..add(d.initializer);
      }
    }
    printer.add(';\n');
  }
}
