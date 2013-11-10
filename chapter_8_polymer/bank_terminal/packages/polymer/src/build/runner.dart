// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Definitions used to run the polymer linter and deploy tools without using
 * pub serve or pub deploy.
 */
library polymer.src.build.runner;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';
import 'package:yaml/yaml.dart';


/** Collects different parameters needed to configure and run barback. */
class BarbackOptions {
  /** Phases of transformers to run. */
  final List<List<Transformer>> phases;

  /** Package to treat as the current package in barback. */
  final String currentPackage;

  /**
   * Mapping between package names and the path in the file system where
   * to find the sources of such package.
   */
  final Map<String, String> packageDirs;

  /** Whether to run transformers on the test folder. */
  final bool transformTests;

  /** Whether to apply transformers on polymer dependencies. */
  final bool transformPolymerDependencies;

  /** Directory where to generate code, if any. */
  final String outDir;

  BarbackOptions(this.phases, this.outDir, {currentPackage, packageDirs,
      this.transformTests: false, this.transformPolymerDependencies: false})
      : currentPackage = (currentPackage != null
          ? currentPackage : readCurrentPackageFromPubspec()),
        packageDirs = (packageDirs != null
          ? packageDirs : _readPackageDirsFromPub(currentPackage));

}

/**
 * Creates a barback system as specified by [options] and runs it.  Returns a
 * future that contains the list of assets generated after barback runs to
 * completion.
 */
Future<AssetSet> runBarback(BarbackOptions options) {
  var barback = new Barback(new _PolymerPackageProvider(options.packageDirs));
  _initBarback(barback, options);
  _attachListeners(barback);
  if (options.outDir == null) return barback.getAllAssets();
  return _emitAllFiles(barback, options);
}

/** Extract the current package from the pubspec.yaml file. */
String readCurrentPackageFromPubspec([String dir]) {
  var pubspec = new File(
      dir == null ? 'pubspec.yaml' : path.join(dir, 'pubspec.yaml'));
  if (!pubspec.existsSync()) {
    print('error: pubspec.yaml file not found, please run this script from '
        'your package root directory.');
    return null;
  }
  return loadYaml(pubspec.readAsStringSync())['name'];
}

/**
 * Extract a mapping between package names and the path in the file system where
 * to find the sources of such package. This map will contain an entry for the
 * current package and everything it depends on (extracted via `pub
 * list-pacakge-dirs`).
 */
Map<String, String> _readPackageDirsFromPub(String currentPackage) {
  var dartExec = Platform.executable;
  // If dartExec == dart, then dart and pub are in standard PATH.
  var sdkDir = dartExec == 'dart' ? '' : path.dirname(dartExec);
  var pub = path.join(sdkDir, Platform.isWindows ? 'pub.bat' : 'pub');
  var result = Process.runSync(pub, ['list-package-dirs']);
  if (result.exitCode != 0) {
    print("unexpected error invoking 'pub':");
    print(result.stdout);
    print(result.stderr);
    exit(result.exitCode);
  }
  var map = JSON.decode(result.stdout)["packages"];
  map.forEach((k, v) { map[k] = path.dirname(v); });
  map[currentPackage] = '.';
  return map;
}

/** Internal packages used by polymer. */
// TODO(sigmund): consider computing this list by recursively parsing
// pubspec.yaml files in the `Options.packageDirs`.
final Set<String> _polymerPackageDependencies = [
    'analyzer', 'args', 'barback', 'browser', 'csslib',
    'custom_element', 'fancy_syntax', 'html5lib', 'html_import', 'js',
    'logging', 'meta', 'mutation_observer', 'observe', 'path'
    'polymer_expressions', 'serialization', 'shadow_dom', 'source_maps',
    'stack_trace', 'template_binding', 'unittest', 'unmodifiable_collection',
    'yaml'].toSet();

/** Return the relative path of each file under [subDir] in [package]. */
Iterable<String> _listPackageDir(String package, String subDir,
    BarbackOptions options) {
  var packageDir = options.packageDirs[package];
  if (packageDir == null) return const [];
  var dir = new Directory(path.join(packageDir, subDir));
  if (!dir.existsSync()) return const [];
  return dir.listSync(recursive: true, followLinks: false)
      .where((f) => f is File)
      .map((f) => path.relative(f.path, from: packageDir));
}

/** A simple provider that reads files directly from the pub cache. */
class _PolymerPackageProvider implements PackageProvider {
  Map<String, String> packageDirs;
  Iterable<String> get packages => packageDirs.keys;

  _PolymerPackageProvider(this.packageDirs);

  Future<Asset> getAsset(AssetId id) => new Future.value(
      new Asset.fromPath(id, path.join(packageDirs[id.package],
      _toSystemPath(id.path))));
}

/** Convert asset paths to system paths (Assets always use the posix style). */
String _toSystemPath(String assetPath) {
  if (path.Style.platform != path.Style.windows) return assetPath;
  return path.joinAll(path.posix.split(assetPath));
}

/** Tell barback which transformers to use and which assets to process. */
void _initBarback(Barback barback, BarbackOptions options) {
  var assets = [];
  void addAssets(String package, String subDir) {
    for (var filepath in _listPackageDir(package, subDir, options)) {
      assets.add(new AssetId(package, filepath));
    }
  }

  for (var package in options.packageDirs.keys) {
    // There is nothing to do in the polymer package dependencies.
    // However: in Polymer package *itself*, we need to replace Observable
    // with ChangeNotifier.
    if (!options.transformPolymerDependencies &&
        _polymerPackageDependencies.contains(package)) continue;
    barback.updateTransformers(package, options.phases);

    // Notify barback to process anything under 'lib' and 'asset'.
    addAssets(package, 'lib');
    addAssets(package, 'asset');
  }

  // In case of the current package, include also 'web'.
  addAssets(options.currentPackage, 'web');
  if (options.transformTests) addAssets(options.currentPackage, 'test');

  barback.updateSources(assets);
}

/** Attach error listeners on [barback] so we can report errors. */
void _attachListeners(Barback barback) {
  // Listen for errors and results
  barback.errors.listen((e) {
    var trace = null;
    if (e is Error) trace = e.stackTrace;
    if (trace != null) {
      print(Trace.format(trace));
    }
    print('error running barback: $e');
    exit(1);
  });

  barback.results.listen((result) {
    if (!result.succeeded) {
      print("build failed with errors: ${result.errors}");
      exit(1);
    }
  });
}

/**
 * Emits all outputs of [barback] and copies files that we didn't process (like
 * polymer's libraries).
 */
Future _emitAllFiles(Barback barback, BarbackOptions options) {
  return barback.getAllAssets().then((assets) {
    // Delete existing output folder before we generate anything
    var dir = new Directory(options.outDir);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    return _emitPackagesDir(options)
      .then((_) => _emitTransformedFiles(assets, options))
      .then((_) => _addPackagesSymlinks(assets, options))
      .then((_) => assets);
  });
}

Future _emitTransformedFiles(AssetSet assets, BarbackOptions options) {
  // Copy all the assets we transformed
  var futures = [];
  var currentPackage = options.currentPackage;
  var transformTests = options.transformTests;
  var outPackages = path.join(options.outDir, 'packages');

  return Future.forEach(assets, (asset) {
    var id = asset.id;
    var dir = _firstDir(id.path);
    if (dir == null) return null;

    var filepath;
    if (dir == 'lib') {
      // Put lib files directly under the packages folder (e.g. 'lib/foo.dart'
      // will be emitted at out/packages/package_name/foo.dart).
      filepath = path.join(outPackages, id.package,
          _toSystemPath(id.path.substring(4)));
    } else if (id.package == currentPackage &&
        (dir == 'web' || (transformTests && dir == 'test'))) {
      filepath = path.join(options.outDir, _toSystemPath(id.path));
    } else {
      // TODO(sigmund): do something about other assets?
      return null;
    }

    return _writeAsset(filepath, asset);
  });
}

/**
 * Adds a package symlink from each directory under `out/web/foo/` to
 * `out/packages`.
 */
Future _addPackagesSymlinks(AssetSet assets, BarbackOptions options) {
  var outPackages = path.join(options.outDir, 'packages');
  var currentPackage = options.currentPackage;
  for (var asset in assets) {
    var id = asset.id;
    if (id.package != currentPackage) continue;
    var firstDir = _firstDir(id.path);
    if (firstDir == null) continue;

    if (firstDir == 'web' || (options.transformTests && firstDir == 'test')) {
      var dir = path.join(options.outDir, path.dirname(_toSystemPath(id.path)));
      var linkPath = path.join(dir, 'packages');
      var link = new Link(linkPath);
      if (!link.existsSync()) {
        var targetPath = Platform.operatingSystem == 'windows'
            ? path.normalize(path.absolute(outPackages))
            : path.normalize(path.relative(outPackages, from: dir));
        link.createSync(targetPath);
      }
    }
  }
}

/**
 * Emits a 'packages' directory directly under `out/packages` with the contents
 * of every file that was not transformed by barback.
 */
Future _emitPackagesDir(BarbackOptions options) {
  if (options.transformPolymerDependencies) return new Future.value(null);
  var outPackages = path.join(options.outDir, 'packages');
  _ensureDir(outPackages);

  // Copy all the files we didn't process
  var dirs = options.packageDirs;

  return Future.forEach(_polymerPackageDependencies, (package) {
    return Future.forEach(_listPackageDir(package, 'lib', options), (relpath) {
      var inpath = path.join(dirs[package], relpath);
      var outpath = path.join(outPackages, package, relpath.substring(4));
      return _copyFile(inpath, outpath);
    });
  });
}

/** Ensure [dirpath] exists. */
void _ensureDir(String dirpath) {
  new Directory(dirpath).createSync(recursive: true);
}

/**
 * Returns the first directory name on a url-style path, or null if there are no
 * slashes.
 */
String _firstDir(String url) {
  var firstSlash = url.indexOf('/');
  if (firstSlash == -1) return null;
  return url.substring(0, firstSlash);
}

/** Copy a file from [inpath] to [outpath]. */
Future _copyFile(String inpath, String outpath) {
  _ensureDir(path.dirname(outpath));
  return new File(inpath).openRead().pipe(new File(outpath).openWrite());
}

/** Write contents of an [asset] into a file at [filepath]. */
Future _writeAsset(String filepath, Asset asset) {
  _ensureDir(path.dirname(filepath));
  return asset.read().pipe(new File(filepath).openWrite());
}
