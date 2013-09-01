// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library html_css_fixup;

import 'dart:json' as json;

import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart';
import 'package:html5lib/dom.dart';
import 'package:html5lib/dom_parsing.dart';

import 'compiler.dart';
import 'emitters.dart';
import 'info.dart';
import 'messages.dart';
import 'options.dart';
import 'paths.dart';
import 'utils.dart';

/**
 * Helper function returns [true] if CSS polyfill is on and component has a
 * scoped style tag.
 */
bool useCssPolyfill(CompilerOptions opts, ComponentInfo component) =>
    opts.processCss && component.scoped;

/**
 *  If processCss is enabled, prefix any component's HTML attributes for id or
 *  class to reference the mangled CSS class name or id.
 */
void fixupHtmlCss(FileInfo fileInfo, CompilerOptions options,
                  CssPolyfillKind polyfillKind(ComponentInfo component)) {
  // Walk the HTML tree looking for class names or id that are in our parsed
  // stylesheet selectors and making those CSS classes and ids unique to that
  // component.
  if (options.verbose) {
    print("  CSS fixup ${path.basename(fileInfo.inputUrl.resolvedPath)}");
  }
  for (var component in fileInfo.declaredComponents) {
    // Mangle class names and element ids in the HTML to match the stylesheet.
    // TODO(terry): Allow more than one style sheet per component.
    if (component.styleSheets.length == 1) {
      // For components only 1 stylesheet allowed.
      var styleSheet = component.styleSheets[0];
      var prefix = polyfillKind(component) == CssPolyfillKind.MANGLED_POLYFILL ?
          component.tagName : null;

      // List of referenced #id and .class in CSS.
      var knownCss = new IdClassVisitor()..visitTree(styleSheet);
      // Prefix all id and class refs in CSS selectors and HTML attributes.
      new _ScopedStyleRenamer(knownCss, prefix, options.debugCss)
          .visit(component);
    }
  }
}

/** Build list of every CSS class name and id selector in a stylesheet. */
class IdClassVisitor extends Visitor {
  final Set<String> classes = new Set();
  final Set<String> ids = new Set();

  void visitClassSelector(ClassSelector node) {
    classes.add(node.name);
  }

  void visitIdSelector(IdSelector node) {
    ids.add(node.name);
  }
}

/** Build the Dart map of managled class/id names and component tag name. */
Map _createCssSimpleSelectors(IdClassVisitor visitedCss, ComponentInfo info,
    bool mangleNames) {
  Map selectors = {};
  if (visitedCss != null) {
    for (var cssClass in visitedCss.classes) {
      selectors['.$cssClass'] =
          mangleNames ? '${info.tagName}_$cssClass' : cssClass;
    }
    for (var id in visitedCss.ids) {
      selectors['#$id'] = mangleNames ? '${info.tagName}_$id' : id;
    }
  }

  // Add tag name selector x-comp == [is="x-comp"].
  var componentName = info.tagName;
  selectors['$componentName'] = '[is="$componentName"]';

  return selectors;
}

/**
 * Return a map of simple CSS selectors (class and id selectors) as a Dart map
 * definition.
 */
String createCssSelectorsExpression(ComponentInfo info, bool mangled) {
  var cssVisited = new IdClassVisitor();

  // For components only 1 stylesheet allowed.
  if (!info.styleSheets.isEmpty && info.styleSheets.length == 1) {
    var styleSheet = info.styleSheets[0];
    cssVisited..visitTree(styleSheet);
  }

  return json.stringify(_createCssSimpleSelectors(cssVisited, info, mangled));
}

// TODO(terry): Need to handle other selectors than IDs/classes like tag name
//              e.g., DIV { color: red; }
// TODO(terry): Would be nice if we didn't need to mangle names; requires users
//              to be careful in their code and makes it more than a "polyfill".
//              Maybe mechanism that generates CSS class name for scoping.  This
//              would solve tag name selectors (see above TODO).
/**
 * Fix a component's HTML to implement scoped stylesheets.
 *
 * We do this by renaming all element class and id attributes to be globally
 * unique to a component.
 *
 * This phase runs after the analyzer and html_cleaner; at that point it's a
 * tree of Infos.  We need to walk element Infos but mangle the HTML elements.
 */
class _ScopedStyleRenamer extends InfoVisitor {
  final bool _debugCss;

  /** Set of classes and ids defined for this component. */
  final IdClassVisitor _knownCss;

  /** Prefix to apply to each class/id reference. */
  final String _prefix;

  _ScopedStyleRenamer(this._knownCss, this._prefix, this._debugCss);

  void visitElementInfo(ElementInfo info) {
    // Walk the HTML elements mangling any references to id or class attributes.
    _mangleClassAttribute(info.node, _knownCss.classes, _prefix);
    _mangleIdAttribute(info.node, _knownCss.ids, _prefix);

    super.visitElementInfo(info);
  }

  /**
   * Mangles HTML class reference that matches a CSS class name defined in the
   * component's style sheet.
   */
  void _mangleClassAttribute(Node node, Set<String> classes, String prefix) {
    if (node.attributes.containsKey('class')) {
      var refClasses = node.attributes['class'].trim().split(" ");

      bool changed = false;
      var len = refClasses.length;
      for (var i = 0; i < len; i++) {
        var refClass = refClasses[i];
        if (classes.contains(refClass)) {
          if (prefix != null) {
            refClasses[i] = '${prefix}_$refClass';
            changed = true;
          }
        }
      }

      if (changed) {
        StringBuffer newClasses = new StringBuffer();
        refClasses.forEach((String className) {
          newClasses.write("${(newClasses.length > 0) ? ' ' : ''}$className");
        });
        var mangledClasses = newClasses.toString();
        if (_debugCss) {
          print("    class = ${node.attributes['class'].trim()} => "
          "$mangledClasses");
        }
        node.attributes['class'] = mangledClasses;
      }
    }
  }

  /**
   * Mangles an HTML id reference that matches a CSS id selector name defined
   * in the component's style sheet.
   */
  void _mangleIdAttribute(Node node, Set<String> ids, String prefix) {
    if (prefix != null) {
      var id = node.attributes['id'];
      if (id != null && ids.contains(id)) {
        var mangledName = '${prefix}_$id';
        if (_debugCss) {
          print("    id = ${node.attributes['id'].toString()} => $mangledName");
        }
        node.attributes['id'] = mangledName;
      }
    }
  }
}


/**
 * Find var- definitions in a style sheet.
 * [found] list of known definitions.
 */
class VarDefinitions extends Visitor {
  final Map<String, VarDefinition> found = new Map();

  void visitTree(StyleSheet tree) {
    visitStyleSheet(tree);
  }

  visitVarDefinition(VarDefinition node) {
    // Replace with latest variable definition.
    found[node.definedName] = node;
    super.visitVarDefinition(node);
  }

  void visitVarDefinitionDirective(VarDefinitionDirective node) {
    visitVarDefinition(node.def);
  }
}

/**
 * Resolve any CSS expression which contains a var() usage to the ultimate real
 * CSS expression value e.g.,
 *
 *    var-one: var(two);
 *    var-two: #ff00ff;
 *
 *    .test {
 *      color: var(one);
 *    }
 *
 * then .test's color would be #ff00ff
 */
class ResolveVarUsages extends Visitor {
  final Map<String, VarDefinition> varDefs;
  bool inVarDefinition = false;
  bool inUsage = false;
  Expressions currentExpressions;

  ResolveVarUsages(this.varDefs);

  void visitTree(StyleSheet tree) {
    visitStyleSheet(tree);
  }

  void visitVarDefinition(VarDefinition varDef) {
    inVarDefinition = true;
    super.visitVarDefinition(varDef);
    inVarDefinition = false;
  }

  void visitExpressions(Expressions node) {
    currentExpressions = node;
    super.visitExpressions(node);
    currentExpressions = null;
  }

  void visitVarUsage(VarUsage node) {
    // Don't process other var() inside of a varUsage.  That implies that the
    // default is a var() too.  Also, don't process any var() inside of a
    // varDefinition (they're just place holders until we've resolved all real
    // usages.
    if (!inUsage && !inVarDefinition && currentExpressions != null) {
      var expressions = currentExpressions.expressions;
      var index = expressions.indexOf(node);
      assert(index >= 0);
      var def = varDefs[node.name];
      if (def != null) {
        // Found a VarDefinition use it.
        _resolveVarUsage(currentExpressions.expressions, index, def);
      } else if (node.defaultValues.any((e) => e is VarUsage)) {
        // Don't have a VarDefinition need to use default values resolve all
        // default values.
        var terminalDefaults = [];
        for (var defaultValue in node.defaultValues) {
          terminalDefaults.addAll(resolveUsageTerminal(defaultValue));
        }
        expressions.replaceRange(index, index + 1, terminalDefaults);
      } else {
        // No VarDefinition but default value is a terminal expression; use it.
        expressions.replaceRange(index, index + 1, node.defaultValues);
      }
    }

    inUsage = true;
    super.visitVarUsage(node);
    inUsage = false;
  }

  List<Expression> resolveUsageTerminal(VarUsage usage) {
    var result = [];

    var varDef = varDefs[usage.name];
    var expressions;
    if (varDef == null) {
      // VarDefinition not found try the defaultValues.
      expressions = usage.defaultValues;
    } else {
      // Use the VarDefinition found.
      expressions = (varDef.expression as Expressions).expressions;
    }

    for (var expr in expressions) {
      if (expr is VarUsage) {
        // Get terminal value.
        result.addAll(resolveUsageTerminal(expr));
      }
    }

    // We're at a terminal just return the VarDefinition expression.
    if (result.isEmpty && varDef != null) {
      result = (varDef.expression as Expressions).expressions;
    }

    return result;
  }

  _resolveVarUsage(List<Expressions> expressions, int index,
                   VarDefinition def) {
    var defExpressions = (def.expression as Expressions).expressions;
    expressions.replaceRange(index, index + 1, defExpressions);
  }
}

/** Remove all var definitions. */
class RemoveVarDefinitions extends Visitor {
  void visitTree(StyleSheet tree) {
    visitStyleSheet(tree);
  }

  void visitStyleSheet(StyleSheet ss) {
    ss.topLevels.removeWhere((e) => e is VarDefinitionDirective);
    super.visitStyleSheet(ss);
  }

  void visitDeclarationGroup(DeclarationGroup node) {
    node.declarations.removeWhere((e) => e is VarDefinition);
    super.visitDeclarationGroup(node);
  }
}

/**
 * Process all selectors looking for a pseudo-element in a selector.  If the
 * name is found in our list of known pseudo-elements.  Known pseudo-elements
 * are built when parsing a component looking for an attribute named "pseudo".
 * The value of the pseudo attribute is the name of the custom pseudo-element.
 * The name is mangled so Dart/JS can't directly access the pseudo-element only
 * CSS can access a custom pseudo-element (and see issue #510, querying needs
 * access to custom pseudo-elements).
 *
 * Change the custom pseudo-element to be a child of the pseudo attribute's
 * mangled custom pseudo element name. e.g,
 *
 *    .test::x-box
 *
 * would become:
 *
 *    .test > *[pseudo="x-box_2"]
 */
class PseudoElementExpander extends Visitor {
  final Map<String, String> _pseudoElements;

  PseudoElementExpander(this._pseudoElements);

  void visitTree(StyleSheet tree) => visitStyleSheet(tree);

  visitSelector(Selector node) {
    var selectors = node.simpleSelectorSequences;
    for (var index = 0; index < selectors.length; index++) {
      var selector = selectors[index].simpleSelector;
      if (selector is PseudoElementSelector) {
        if (_pseudoElements.containsKey(selector.name)) {
          // Pseudo Element is a custom element.
          var mangledName = _pseudoElements[selector.name];

          var span = selectors[index].span;

          var attrSelector = new AttributeSelector(
              new Identifier('pseudo', span), css.TokenKind.EQUALS,
              mangledName, span);
          // The wildcard * namespace selector.
          var wildCard = new ElementSelector(new Wildcard(span), span);
          selectors[index] = new SimpleSelectorSequence(wildCard, span,
                  css.TokenKind.COMBINATOR_GREATER);
          selectors.insert(++index,
              new SimpleSelectorSequence(attrSelector, span));
        }
      }
    }
  }
}

/** Compute each CSS URI resource relative from the generated CSS file. */
class UriVisitor extends Visitor {
  /**
   * Relative path from the output css file to the location of the original
   * css file that contained the URI to each resource.
   */
  final String _pathToOriginalCss;

  factory UriVisitor(PathMapper pathMapper, String cssPath, bool rewriteUrl) {
    var cssDir = path.dirname(cssPath);
    var outCssDir = rewriteUrl ? pathMapper.outputDirPath(cssPath)
        : path.dirname(cssPath);
    return new UriVisitor._internal(path.relative(cssDir, from: outCssDir));
  }

  UriVisitor._internal(this._pathToOriginalCss);

  void visitUriTerm(UriTerm node) {
    // Don't touch URIs that have any scheme (http, etc.).
    var uri = Uri.parse(node.text);
    if (uri.host != '') return;
    if (uri.scheme != '' && uri.scheme != 'package') return;

    node.text = pathToUrl(
        path.normalize(path.join(_pathToOriginalCss, node.text)));
  }
}

List<UrlInfo> findImportsInStyleSheet(StyleSheet styleSheet,
    String packageRoot, UrlInfo inputUrl, Messages messages) {
  var visitor = new CssImports(packageRoot, inputUrl, messages);
  visitor.visitTree(styleSheet);
  return visitor.urlInfos;
}

/**
 * Find any imports in the style sheet; normalize the style sheet href and
 * return a list of all fully qualified CSS files.
 */
class CssImports extends Visitor {
  final String packageRoot;

  /** Input url of the css file, used to normalize relative import urls. */
  final UrlInfo inputUrl;

  /** List of all imported style sheets. */
  final List<UrlInfo> urlInfos = [];

  final Messages _messages;

  CssImports(this.packageRoot, this.inputUrl, this._messages);

  void visitTree(StyleSheet tree) {
    visitStyleSheet(tree);
  }

  void visitImportDirective(ImportDirective node) {
    var urlInfo = UrlInfo.resolve(node.import, inputUrl,
        node.span, packageRoot, _messages, ignoreAbsolute: true);
    if (urlInfo == null) return;
    urlInfos.add(urlInfo);
  }
}

StyleSheet parseCss(String content, Messages messages,
    CompilerOptions options) {
  if (content.trim().isEmpty) return null;

  var errors = [];

  // TODO(terry): Add --checked when fully implemented and error handling.
  var stylesheet = css.parse(content, errors: errors, options:
      [options.warningsAsErrors ? '--warnings_as_errors' : '', 'memory']);

  // Note: errors aren't fatal in HTML (unless strict mode is on).
  // So just print them as warnings.
  for (var e in errors) {
    messages.warning(e.message, e.span);
  }

  return stylesheet;
}

/** Find terminal definition (non VarUsage implies real CSS value). */
VarDefinition findTerminalVarDefinition(Map<String, VarDefinition> varDefs,
                                        VarDefinition varDef) {
  var expressions = varDef.expression as Expressions;
  for (var expr in expressions.expressions) {
    if (expr is VarUsage) {
      var usageName = (expr as VarUsage).name;
      var foundDef = varDefs[usageName];

      // If foundDef is unknown check if defaultValues; if it exist then resolve
      // to terminal value.
      if (foundDef == null) {
        // We're either a VarUsage or terminal definition if in varDefs;
        // either way replace VarUsage with it's default value because the
        // VarDefinition isn't found.
        var defaultValues = (expr as VarUsage).defaultValues;
        var replaceExprs = expressions.expressions;
        assert(replaceExprs.length == 1);
        replaceExprs.replaceRange(0, 1, defaultValues);
        return varDef;
      }
      if (foundDef is VarDefinition) {
        return findTerminalVarDefinition(varDefs, foundDef);
      }
    } else {
      // Return real CSS property.
      return varDef;
    }
  }

  // Didn't point to a var definition that existed.
  return varDef;
}

/**
 * Find urls imported inside style tags under [info].  If [info] is a FileInfo
 * then process only style tags in the body (don't process any style tags in a
 * component).  If [info] is a ComponentInfo only process style tags inside of
 * the element are processed.  For an [info] of type FileInfo [node] is the
 * file's document and for an [info] of type ComponentInfo then [node] is the
 * component's element tag.
 */
List<UrlInfo> findUrlsImported(LibraryInfo info, UrlInfo inputUrl,
    String packageRoot, Node node, Messages messages, CompilerOptions options) {
  // Process any @imports inside of the <style> tag.
  var styleProcessor =
      new CssStyleTag(packageRoot, info, inputUrl, messages, options);
  styleProcessor.visit(node);
  return styleProcessor.imports;
}

/* Process CSS inside of a style tag. */
class CssStyleTag extends TreeVisitor {
  final String _packageRoot;

  /** Either a FileInfo or ComponentInfo. */
  final LibraryInfo _info;
  final Messages _messages;
  final CompilerOptions _options;

  /**
   * Path of the declaring file, for a [_info] of type FileInfo it's the file's
   * path for a type ComponentInfo it's the declaring file path.
   */
  final UrlInfo _inputUrl;

  /** List of @imports found. */
  List<UrlInfo> imports = [];

  CssStyleTag(this._packageRoot, this._info, this._inputUrl, this._messages,
      this._options);

  void visitElement(Element node) {
    // Don't process any style tags inside of element if we're processing a
    // FileInfo.  The style tags inside of a component defintion will be
    // processed when _info is a ComponentInfo.
    if (node.tagName == 'element' && _info is FileInfo) return;
    if (node.tagName == 'style') {
      // Parse the contents of the scoped style tag.
      var styleSheet = parseCss(node.nodes.single.value, _messages, _options);
      if (styleSheet != null) {
        _info.styleSheets.add(styleSheet);

        // TODO(terry): Check on scoped attribute there's a rumor that styles
        //              might always be scoped in a component.
        // TODO(terry): May need to handle multiple style tags some with scoped
        //              and some without for now first style tag determines how
        //              CSS is emitted.
        if (node.attributes.containsKey('scoped') && _info is ComponentInfo) {
          (_info as ComponentInfo).scoped = true;
        }

        // Find all imports return list of @imports in this style tag.
        var urlInfos = findImportsInStyleSheet(styleSheet, _packageRoot,
            _inputUrl, _messages);
        imports.addAll(urlInfos);
      }
    }
    super.visitElement(node);
  }
}
