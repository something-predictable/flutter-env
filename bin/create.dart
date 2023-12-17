import 'dart:io';
import 'dart:isolate';

import 'package:riddance_env/git.dart' as git;
import 'package:riddance_env/pub.dart';
import 'package:riddance_env/template.dart';

void main(List<String> arguments) async {
  final path = Directory.current;
  final package = await makePubspecYaml(path, arguments);
  final templatePath = await Isolate.resolvePackageUri(
    Uri.parse('package:riddance_env/template/'),
  );
  if (templatePath != null) {
    final packageNameFixes = <String, String Function(String)>{
      'lib/main.dart': (contents) =>
          contents.replaceAll('flutter_create', package.name),
      'test/smoke_test.dart': (contents) =>
          contents.replaceAll('flutter_create', package.name),
    };
    await copyTemplate(
      path,
      templatePath,
      [
        'overlay',
        'app',
      ],
      packageNameFixes,
    );
    await orderImports(path, packageNameFixes.keys);
  }

  git.init(path);
  await git.addAndCommit(path, ['fltr', 'create', ...arguments].join(' '));

  await Process.run(
    'code',
    ['--goto', './lib/main.dart:15:41', '.'],
    runInShell: true,
  );
}
