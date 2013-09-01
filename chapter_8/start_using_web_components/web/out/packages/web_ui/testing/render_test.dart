// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This is a helper for run.sh. We try to run all of the Dart code in one
 * instance of the Dart VM to reduce warm-up time.
 */
library web_ui.testing.render_test;

import 'dart:io';
import 'dart:math' show min;
import 'package:pathos/path.dart' as path;
import 'package:unittest/unittest.dart';
import 'package:web_ui/dwc.dart' as dwc;

void renderTests(String baseDir, String inputDir, String expectedDir,
    String outDir, {List<String> arguments, String script, String pattern,
    bool deleteDir: true}) {
  if (arguments == null) arguments = new Options().arguments;
  if (script == null) script = new Options().script;

  var filePattern = new RegExp(pattern != null ? pattern
      : (arguments.length > 0 ? arguments.removeAt(0) : '.'));

  var scriptDir = path.absolute(path.dirname(script));
  baseDir = path.join(scriptDir, baseDir);
  inputDir = path.join(scriptDir, inputDir);
  expectedDir = path.join(scriptDir, expectedDir);
  outDir = path.join(scriptDir, outDir);

  var paths = new Directory(inputDir).listSync()
      .where((f) => f is File).map((f) => f.path)
      .where((p) => p.endsWith('_test.html') && filePattern.hasMatch(p));

  // First clear the output folder. Otherwise we can miss bugs when we fail to
  // generate a file.
  var dir = new Directory(outDir);
  if (dir.existsSync() && deleteDir) {
    print('Cleaning old output for ${path.normalize(outDir)}');
    dir.deleteSync(recursive: true);
  }
  dir.createSync();

  arguments.addAll(['-o', outDir, '--basedir', baseDir]);
  for (var filePath in paths) {
    var filename = path.basename(filePath);
    test('compile $filename', () {
      var testArgs = arguments.toList();
      testArgs.add(filePath);
      expect(dwc.run(testArgs, printTime: false).then((res) {
        expect(res.messages.length, 0, reason: res.messages.join('\n'));
      }), completes);
    });
  }

  if (!paths.isEmpty) {
    var filenames = paths.map(path.basename).toList();
    // Sort files to match the order in which run.sh runs diff.
    filenames.sort();
    var outs;

    // Get the path from "input" relative to "baseDir"
    var relativeToBase = path.relative(inputDir, from: baseDir);

    test('content_shell run', () {
      var args = ['--dump-render-tree'];
      args.addAll(filenames.map((name) =>
          'file://${path.join(outDir, relativeToBase, name)}'));
      expect(Process.run('content_shell', args).then((res) {
        expect(res.exitCode, 0, reason: 'content_shell exit code: '
          '${res.exitCode}. Contents of stderr: \n${res.stderr}');
        outs = res.stdout.split('#EOF\n')
          .where((s) => !s.trim().isEmpty).toList();
        expect(outs.length, filenames.length);
      }), completes);
    });

    for (int i = 0; i < filenames.length; i++) {
      var filename = filenames[i];
      // TODO(sigmund): remove this extra variable dartbug.com/8698
      int j = i;
      test('verify $filename', () {
        expect(outs, isNotNull, reason:
          'Output not available, maybe content_shell failed to run.');
        var output = outs[j];
        var outPath = path.join(outDir, '$filename.txt');
        var expectedPath = path.join(expectedDir, '$filename.txt');
        new File(outPath).writeAsStringSync(output);
        var expected = new File(expectedPath).readAsStringSync();
        expect(output, expected,
          reason: 'unexpected output for <$filename>');
      });
    }
  }
}
