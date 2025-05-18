import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

String _content(
  String flutterVersion,
  String packageName,
  String appName,
  String domain,
) => '''
name: $packageName
publish_to: none
version: 0.0.1

app:
  name: $appName
  domain: $domain
  permissions:
    - internet-client

environment:
  flutter: $flutterVersion
  sdk: ^3.7.0

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
''';

const _allPlatforms = [
  'android',
  'ios',
  'linux',
  'windows',
  'macos',
  'web',
  'webos',
];

Future<PackageInfo> makePubspecYaml(
  Directory path,
  List<String> arguments,
) async {
  final packageName = basename(path.path);
  final appName = _after('--app-name', arguments) ?? _defaultName(packageName);
  final domain = _reverse(_after('--org', arguments)) ?? 'example.com';
  final pubspecFile = File('${path.path}${Platform.pathSeparator}pubspec.yaml')
    ..writeAsStringSync(
      _content(await _flutterVersion(), packageName, appName, domain),
    );
  await _flutterExec(path, ['pub', 'add', 'dev:riddance_env']);
  final myVersion = _freezeVersion(pubspecFile);
  try {
    File('${path.path}${Platform.pathSeparator}pubspec.lock').deleteSync();
  } on PathNotFoundException catch (_) {}
  await _flutterExec(path, ['pub', 'get']);
  return PackageInfo(
    packageName,
    appName,
    '0.0.1',
    domain,
    null,
    [],
    false,
    _allPlatforms,
    ['internet-client'],
    myVersion,
  );
}

Future<PackageInfo?> readPubspec(Directory path) async => switch (loadYaml(
  await File(
    '${path.path}${Platform.pathSeparator}pubspec.yaml',
  ).readAsString(),
)) {
  (final YamlMap doc) => switch ((
    doc['name'],
    doc['version'],
    doc['description'],
    doc['topics'],
    doc['dev_dependencies'],
    doc['app'],
    doc['platforms'],
  )) {
    (
      final String name,
      final String version,
      final String? description,
      final YamlList? topics,
      final YamlMap deps,
      final YamlMap app,
      final Object? platforms,
    ) =>
      switch ((
        deps['riddance_env'],
        app['name'],
        app['domain'],
        app['orientation'],
        app['unsupported'],
        app['permissions'],
      )) {
        (
          final String myVersion,
          final String appName,
          final String domain,
          final String? orientation,
          final Object? unsupported,
          final Object? permissions,
        ) =>
          PackageInfo(
            name,
            appName,
            version,
            domain,
            description,
            topics?.whereType<String>().toList() ?? [],
            orientation == 'portrait',
            switch ((platforms, unsupported)) {
              (final YamlList platforms, final YamlList unsupported) => [
                ...platforms.whereType<String>().where(
                  (element) => !unsupported.contains(element),
                ),
              ],
              (final YamlMap platforms, final YamlList unsupported) => [
                ...platforms.keys.whereType<String>().where(
                  (element) => !unsupported.contains(element),
                ),
              ],
              (final YamlList platforms, final String unsupported) => [
                ...platforms.whereType<String>().where(
                  (element) => element != unsupported,
                ),
              ],
              (final YamlMap platforms, final String unsupported) => [
                ...platforms.keys.whereType<String>().where(
                  (element) => element != unsupported,
                ),
              ],
              (null, final YamlList unsupported) => [
                ..._allPlatforms.where(
                  (element) => !unsupported.contains(element),
                ),
              ],
              (null, final String unsupported) => [
                ..._allPlatforms.where((element) => element != unsupported),
              ],
              (final YamlList platforms, null) => [
                ...platforms.whereType<String>(),
              ],
              (final YamlMap platforms, null) => [
                ...platforms.keys.whereType<String>(),
              ],
              _ => _allPlatforms,
            },
            switch (permissions) {
              (final YamlList permissions) => [
                ...permissions.whereType<String>(),
              ],
              _ => [],
            },
            myVersion,
          ),
        _ => null,
      },
    _ => null,
  },
  _ => null,
};

final class PackageInfo {
  const PackageInfo(
    this.name,
    this.appName,
    this.appVersion,
    this.domain,
    this.description,
    this.topics,
    // ignore: avoid_positional_boolean_parameters
    this.portrait,
    this.platforms,
    this.permissions,
    this.myVersion,
  );

  final String name;
  final String appName;
  final String appVersion;
  final String domain;
  final String? description;
  final List<String> topics;
  final bool portrait;
  final List<String> platforms;
  List<String> get unsupported =>
      _allPlatforms.where((p) => !platforms.contains(p)).toList();
  final List<String> permissions;
  final String myVersion;
}

String _defaultName(String packageName) => packageName
    .split('_')
    .where((e) => e != 'flutter')
    .map((e) => e.substring(0, 1).toUpperCase() + e.substring(1))
    .join(' ');

String? _reverse(String? org) => org?.split('.').reversed.join('.');

final _myVersionRegExp = RegExp(
  r'  riddance_env: \^([0-9]+)\.([0-9]+)\.([0-9]+)',
);

String _freezeVersion(File pubspecFile) {
  final contents = pubspecFile.readAsStringSync();
  final m = _myVersionRegExp.allMatches(contents).single;
  final version = '${m.group(1)}.${m.group(2)}.${m.group(3)}';
  final start = contents.substring(0, m.start);
  final end = contents.substring(m.end);
  pubspecFile.writeAsStringSync('$start  riddance_env: $version$end');
  return version;
}

String? _after(String parameter, List<String> arguments) {
  final ix = arguments.indexOf(parameter);
  if (ix == -1 || ix == arguments.length - 1) {
    return null;
  }
  return arguments[ix + 1];
}

Future<String> _flutterVersion() async {
  try {
    // ignore: avoid_dynamic_calls
    return jsonDecode(
      await _flutterExec(null, ['--version', '--machine']),
    )['frameworkVersion'];
  } catch (e) {
    // ignore: avoid_print
    print('Unable to determine flutter version.');
    exit(1);
  }
}

Future<String> _flutterExec(Directory? path, List<String> arguments) async {
  final process = await Process.start(
    'flutter',
    arguments,
    workingDirectory: path?.path,
    runInShell: true,
  );
  final stdOut = StringBuffer();
  final streams = Future.wait([
    process.stderr.pipe(stderr),
    process.stdout.transform(utf8.decoder).listen(stdOut.write).asFuture(),
  ]);
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    exit(exitCode);
  }
  await streams;
  return stdOut.toString();
}
