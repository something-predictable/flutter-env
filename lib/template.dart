import 'dart:io';

Future<void> copyTemplate(
  Directory target,
  Uri templatePath,
  List<String> templates,
  Map<String, String Function(String)> replacer,
) async {
  final directories = <String, Directory>{};
  final files = <String, File>{};
  for (final template in templates) {
    await _collect(templatePath, template, directories, files);
  }
  for (final e in directories.entries) {
    Directory(target.path + Platform.pathSeparator + e.key).createSync();
  }
  for (final e in files.entries) {
    final targetFile = target.path + Platform.pathSeparator + e.key;
    if (_replace(e.key, e.value.path, targetFile, replacer)) {
      continue;
    }
    await e.value.copy(targetFile.replaceAll('_gitignore', '.gitignore'));
  }
}

bool _replace(
  String sourcePath,
  String source,
  String target,
  Map<String, String Function(String)> replacer,
) {
  final r = replacer[sourcePath.replaceAll(Platform.pathSeparator, '/')];
  if (r == null) {
    return false;
  }
  File(target).writeAsStringSync(r(File(source).readAsStringSync()));
  return true;
}

Future<void> _collect(
  Uri templatePath,
  String template,
  Map<String, Directory> directories,
  Map<String, File> files,
) async {
  final dir = Directory.fromUri(templatePath.resolve(template));
  await for (final file in dir.list(recursive: true)) {
    final rel = file.path.substring(dir.path.length + 1);
    final _ = switch (file) {
      (final Directory d) => directories[rel] = d,
      (final File f) => files[rel] = f,
      _ => null,
    };
  }
}

Future<void> orderImports(Directory path, Iterable<String> files) async {
  await Future.wait(
    files.map(
      (file) => _dartExec(
        path,
        ['fix', '--apply', '--code=directives_ordering', file],
      ),
    ),
  );
}

Future<void> _dartExec(Directory path, List<String> arguments) async {
  final process = await Process.start(
    'dart',
    arguments,
    workingDirectory: path.path,
    runInShell: true,
  );
  await process.exitCode;
}
