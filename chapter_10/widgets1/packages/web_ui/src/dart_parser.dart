// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Parser for Dart code based on the experimental analyzer.
 */
library dart_parser;

import 'dart:utf';
import 'dart:math' as math;
import 'package:analyzer_experimental/src/generated/ast.dart';
import 'package:analyzer_experimental/src/generated/error.dart';
import 'package:analyzer_experimental/src/generated/parser.dart';
import 'package:analyzer_experimental/src/generated/scanner.dart';
import 'package:source_maps/span.dart' show SourceFile, SourceFileSegment, Location;
import 'info.dart';
import 'messages.dart';
import 'refactor.dart' show $CR, $LF;
import 'utils.dart';

/** Information extracted from a source Dart file. */
class DartCodeInfo extends Hashable {

  /** Library qualified identifier, if any. */
  final String libraryName;

  /** Library which the code is part-of, if any. */
  final String partOf;

  /** Declared imports, exports, and parts. */
  final List<Directive> directives;

  /** Source file representation used to compute source map information. */
  final SourceFile sourceFile;

  /** The parsed code. */
  final CompilationUnit compilationUnit;

  /** The full source code. */
  final String code;

  DartCodeInfo(this.libraryName, this.partOf, this.directives, code,
      this.sourceFile, [compilationUnit])
      : this.code = code,
        this.compilationUnit = compilationUnit == null
          ? parseCompilationUnit(code) : compilationUnit;

  bool get isPart =>
      compilationUnit.directives.any((d) => d is PartOfDirective);

  int get directivesEnd {
    if (compilationUnit.directives.length == 0) return 0;
    return compilationUnit.directives.last.end;
  }

  /**
   * The position of the first "part" directive. If none is found,
   * this behaves like [directivesEnd].
   */
  int get firstPartOffset {
    for (var directive in compilationUnit.directives) {
      if (directive is PartDirective) return directive.offset;
    }
    // No part directives, just return directives end.
    return directivesEnd;
  }

  /** Gets the code after the [directives]. */
  String codeAfterDirectives() => code.substring(directivesEnd);

  ClassDeclaration findClass(String name) {
    for (var decl in compilationUnit.declarations) {
      if (decl is ClassDeclaration) {
        if (decl.name.name == name) return decl;
      }
    }
    return null;
  }
}

SimpleStringLiteral createStringLiteral(String contents) {
  var lexeme = "'${escapeDartString(contents)}'";
  var token = new StringToken(TokenType.STRING, lexeme, null);
  return new SimpleStringLiteral.full(token, contents);
}


/**
 * Parse and extract top-level directives from [code].
 *
 * Adds emitted error/warning messages to [messages], if [messages] is
 * supplied.
 */
DartCodeInfo parseDartCode(String path, String code, Messages messages,
    [Location offset]) {
  var unit = parseCompilationUnit(code, path: path, messages: messages);

  // Extract some information from the compilation unit.
  String libraryName, partName;
  var directives = [];
  int directiveEnd = 0;
  for (var directive in unit.directives) {
    if (directive is LibraryDirective) {
      libraryName = directive.name.name;
    } else if (directive is PartOfDirective) {
      partName = directive.libraryName.name;
    } else {
      assert(directive is UriBasedDirective);
      // Normalize the library URI.
      var uriNode = directive.uri;
      if (uriNode is! SimpleStringLiteral) {
        String uri = uriNode.accept(new ConstantEvaluator(null));
        directive.uri = createStringLiteral(uri);
      }
      directives.add(directive);
    }
  }

  var sourceFile = offset == null
      ? new SourceFile.text(path, code)
      : new SourceFileSegment(path, code, offset);

  return new DartCodeInfo(libraryName, partName, directives, code,
      sourceFile, unit);
}

CompilationUnit parseCompilationUnit(String code, {String path,
    Messages messages}) {

  var errorListener = new _ErrorCollector();
  var scanner = new StringScanner(null, code, errorListener);
  var token = scanner.tokenize();
  var parser = new Parser(null, errorListener);
  var unit = parser.parseCompilationUnit(token);

  if (path == null || messages == null) return unit;

  // TODO(jmesserly): removed this for now because the analyzer doesn't format
  // messages properly, so you end up with things like "Unexpected token '%s'".
  // This used to convert parser messages into our messages. Enable this
  // once analyzer is fixed.
  // TODO(sigmund): once we enable this, we need to fix compiler.dart to clear
  // out the output of the compiler if we see compilation errors.
  if (false) {
    var file = new SourceFile.text(path, code);
    for (var e in errorListener.errors) {
      var span = file.span(e.offset, e.offset + e.length);

      var severity = e.errorCode.errorSeverity;
      if (severity == ErrorSeverity.ERROR) {
        messages.error(e.message, span);
      } else {
        assert(severity == ErrorSeverity.WARNING);
        messages.warning(e.message, span);
      }
    }
  }

  return unit;
}

class _ErrorCollector extends AnalysisErrorListener {
  final errors = new List<AnalysisError>();
  onError(error) => errors.add(error);
}
