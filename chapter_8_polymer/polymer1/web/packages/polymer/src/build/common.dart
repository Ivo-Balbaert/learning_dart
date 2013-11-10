// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Common methods used by transfomers. */
library polymer.src.build.common;

import 'dart:async';

import 'package:barback/barback.dart';
import 'package:html5lib/dom.dart' show Document;
import 'package:html5lib/parser.dart' show HtmlParser;
import 'package:path/path.dart' as path;
import 'package:source_maps/span.dart' show Span;

/**
 * Parses an HTML file [contents] and returns a DOM-like tree. Adds emitted
 * error/warning to [logger].
 */
Document _parseHtml(String contents, String sourcePath, TransformLogger logger,
    {bool checkDocType: true}) {
  // TODO(jmesserly): make HTTP encoding configurable
  var parser = new HtmlParser(contents, encoding: 'utf8', generateSpans: true,
      sourceUrl: sourcePath);
  var document = parser.parse();

  // Note: errors aren't fatal in HTML (unless strict mode is on).
  // So just print them as warnings.
  for (var e in parser.errors) {
    if (checkDocType || e.errorCode != 'expected-doctype-but-got-start-tag') {
      logger.warning(e.message, span: e.span);
    }
  }
  return document;
}

/** Additional options used by polymer transformers */
class TransformOptions {
  /**
   * List of entrypoints paths. The paths are relative to the package root and
   * are represented using posix style, which matches the representation used in
   * asset ids in barback. If null, anything under 'web/' or 'test/' is
   * considered an entry point.
   */
  final List<String> entryPoints;

  /**
   * True to enable Content Security Policy.
   * This means the HTML page will include *.dart.precompiled.js
   *
   * This flag has no effect unless [directlyIncludeJS] is enabled.
   */
  final bool contentSecurityPolicy;

  /**
   * True to include the compiled JavaScript directly from the HTML page.
   * If enabled this will remove "packages/browser/dart.js" and replace
   * `type="application/dart"` scripts with equivalent *.dart.js files.
   *
   * If [contentSecurityPolicy] enabled, this will reference files
   * named *.dart.precompiled.js.
   */
  final bool directlyIncludeJS;

  TransformOptions({entryPoints, this.contentSecurityPolicy: false,
      this.directlyIncludeJS: true})
      : entryPoints = entryPoints == null ? null
          : entryPoints.map(_systemToAssetPath).toList();

  /** Whether an asset with [id] is an entry point HTML file. */
  bool isHtmlEntryPoint(AssetId id) {
    if (id.extension != '.html') return false;

    // Note: [id.path] is a relative path from the root of a package.
    if (entryPoints == null) {
      return id.path.startsWith('web/') || id.path.startsWith('test/');
    }

    return entryPoints.contains(id.path);
  }
}

/** Mixin for polymer transformers. */
abstract class PolymerTransformer {
  TransformOptions get options;

  Future<Document> readPrimaryAsHtml(Transform transform) {
    var asset = transform.primaryInput;
    var id = asset.id;
    return asset.readAsString().then((content) {
      return _parseHtml(content, id.path, transform.logger,
        checkDocType: options.isHtmlEntryPoint(id));
    });
  }

  Future<Document> readAsHtml(AssetId id, Transform transform) {
    var primaryId = transform.primaryInput.id;
    bool samePackage = id.package == primaryId.package;
    var url = samePackage ? id.path
        : assetUrlFor(id, primaryId, transform.logger, allowAssetUrl: true);
    return transform.readInputAsString(id).then((content) {
      return _parseHtml(content, url, transform.logger,
        checkDocType: samePackage && options.isHtmlEntryPoint(id));
    });
  }

  Future<bool> assetExists(AssetId id, Transform transform) =>
      transform.getInput(id).then((_) => true).catchError((_) => false);
}

/** Create an [AssetId] for a [url] seen in the [source] asset. */
// TODO(sigmund): delete once this is part of barback (dartbug.com/12610)
AssetId resolve(AssetId source, String url, TransformLogger logger, Span span) {
  if (url == null || url == '') return null;
  var uri = Uri.parse(url);
  var urlBuilder = path.url;
  if (uri.host != '' || uri.scheme != '' || urlBuilder.isAbsolute(url)) {
    logger.error('absolute paths not allowed: "$url"', span: span);
    return null;
  }

  var package;
  var targetPath;
  var segments = urlBuilder.split(url);
  if (segments[0] == 'packages') {
    if (segments.length < 3) {
      logger.error("incomplete packages/ path. It should have at least 3 "
          "segments packages/name/path-from-name's-lib-dir", span: span);
      return null;
    }
    package = segments[1];
    targetPath = urlBuilder.join('lib',
        urlBuilder.joinAll(segments.sublist(2)));
  } else if (segments[0] == 'assets') {
    if (segments.length < 3) {
      logger.error("incomplete assets/ path. It should have at least 3 "
          "segments assets/name/path-from-name's-asset-dir", span: span);
    }
    package = segments[1];
    targetPath = urlBuilder.join('asset',
        urlBuilder.joinAll(segments.sublist(2)));
  } else {
    package = source.package;
    targetPath = urlBuilder.normalize(
        urlBuilder.join(urlBuilder.dirname(source.path), url));
  }
  return new AssetId(package, targetPath);
}

/**
 * Generate the import url for a file described by [id], referenced by a file
 * with [sourceId].
 */
// TODO(sigmund): this should also be in barback (dartbug.com/12610)
String assetUrlFor(AssetId id, AssetId sourceId, TransformLogger logger,
    {bool allowAssetUrl: false}) {
  // use package: and asset: urls if possible
  if (id.path.startsWith('lib/')) {
    return 'package:${id.package}/${id.path.substring(4)}';
  }

  if (id.path.startsWith('asset/')) {
    if (!allowAssetUrl) {
      logger.error("asset urls not allowed. "
          "Don't know how to refer to $id from $sourceId");
      return null;
    }
    return 'asset:${id.package}/${id.path.substring(6)}';
  }

  // Use relative urls only if it's possible.
  if (id.package != sourceId.package) {
    logger.error("don't know how to refer to $id from $sourceId");
    return null;
  }

  var builder = path.url;
  return builder.relative(builder.join('/', id.path),
      from: builder.join('/', builder.dirname(sourceId.path)));
}


/** Convert system paths to asset paths (asset paths are posix style). */
String _systemToAssetPath(String assetPath) {
  if (path.Style.platform != path.Style.windows) return assetPath;
  return path.posix.joinAll(path.split(assetPath));
}
