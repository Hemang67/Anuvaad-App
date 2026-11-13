import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// GitHub rejects a workflow with invalid YAML only after it is pushed, so parse them here.
void main() {
  final workflows = Directory('.github/workflows')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.yml') || f.path.endsWith('.yaml'))
      .toList();

  test('workflow files exist', () {
    expect(workflows.map((f) => f.uri.pathSegments.last), containsAll(['ci.yml', 'release.yml']));
  });

  for (final file in workflows) {
    test('${file.uri.pathSegments.last} is valid YAML with jobs and steps', () {
      final doc = loadYaml(file.readAsStringSync()) as YamlMap;
      final jobs = doc['jobs'] as YamlMap;
      expect(jobs, isNotEmpty);
      for (final job in jobs.values) {
        for (final step in (job as YamlMap)['steps'] as YamlList) {
          final run = (step as YamlMap)['run'];
          if (run != null) expect(run, isA<String>(), reason: 'run must be a string: $step');
        }
      }
    });
  }

  test('CI and release build with the same pinned Flutter, never whatever stable is today', () {
    // An unpinned stable moved to 3.50 (new deprecations, newer Gradle plugin) and broke the 0.4.0 release.
    final pins = <String>{};
    for (final name in ['ci.yml', 'release.yml']) {
      final doc = loadYaml(File('.github/workflows/$name').readAsStringSync()) as YamlMap;
      final steps = [for (final job in (doc['jobs'] as YamlMap).values) ...((job as YamlMap)['steps'] as YamlList)];
      final flutter = steps.cast<YamlMap>().singleWhere((s) => '${s['uses']}'.startsWith('subosito/flutter-action'));
      final version = (flutter['with'] as YamlMap)['flutter-version'];
      expect(version, matches(RegExp(r'^\d+\.\d+\.\d+$')), reason: '$name pins an exact Flutter version');
      pins.add('$version');
    }
    expect(pins, hasLength(1), reason: 'CI tests what the release builds');
  });

  test('release workflow runs only for version tags', () {
    final doc = loadYaml(File('.github/workflows/release.yml').readAsStringSync()) as YamlMap;
    // YAML 1.1 reads a bare `on` key as true.
    final on = (doc['on'] ?? doc[true]) as YamlMap;
    expect((on['push'] as YamlMap)['tags'], ['v*.*.*']);
    expect((on['push'] as YamlMap).containsKey('branches'), isFalse);
  });

  test('every release APK is checked for the permissions screen-off conversations need', () {
    final script = File('tool/release/check_apk.sh').readAsStringSync();
    for (final permission in ['RECORD_AUDIO', 'FOREGROUND_SERVICE_MICROPHONE', 'POST_NOTIFICATIONS']) {
      expect(script, contains('android.permission.$permission'));
    }
  });
}
