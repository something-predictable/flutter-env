import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';

String _content(
  String flutterVersion,
  String packageName,
  String appName,
  String domain,
) =>
    '''
name: $packageName
publish_to: 'none'
version: 0.0.1

app:
  name: $appName
  domain: $domain
  permissions:
    - internet-client

environment:
  flutter: $flutterVersion
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
''';

Future<void> makePubspecYaml(Directory path, List<String> arguments) async {
  final packageName = basename(path.path);
  final pubspecFile = File('${path.path}${Platform.pathSeparator}pubspec.yaml')
    ..writeAsStringSync(
      _content(
        await _flutterVersion(),
        packageName,
        _after('--app-name', arguments) ?? _defaultName(packageName),
        _reverse(_after('--org', arguments)) ?? 'example.com',
      ),
    );
  await _flutterExec(path, ['pub', 'add', 'dev:riddance_env']);
  pubspecFile.writeAsStringSync(
    pubspecFile.readAsStringSync().replaceAllMapped(
          RegExp(r'  riddance_env: \^([0-9]+)\.([0-9]+)\.([0-9]+)'),
          (m) => '  riddance_env: ${m.group(1)}.${m.group(2)}.${m.group(3)}',
        ),
  );
  try {
    File('${path.path}${Platform.pathSeparator}pubspec.lock').deleteSync();
  } on PathNotFoundException catch (_) {}
  await _flutterExec(path, ['pub', 'get']);
}

String _defaultName(String packageName) => packageName
    .split('_')
    .where((e) => e != 'flutter')
    .map((e) => e.substring(0, 1).toUpperCase() + e.substring(1))
    .join(' ');

String? _reverse(String? org) => org?.split('.').reversed.join('.');

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
    'dart',
    ['pub', 'global', 'run', 'fltr', ...arguments],
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
