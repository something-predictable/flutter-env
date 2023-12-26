import 'dart:io';

final class Template {
  const Template(this.name, [this.onlyInclude]);

  final String name;
  final List<String>? onlyInclude;
}

Future<void> copyTemplate(
  Directory target,
  Uri templatePath,
  List<Template> templates,
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
    await e.value.copy(targetFile);
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
  Template template,
  Map<String, Directory> directories,
  Map<String, File> files,
) async {
  final dir = Directory.fromUri(templatePath.resolve(template.name));
  await for (final file in dir.list(recursive: true)) {
    final rel = _dotFile(_relative(dir.path, file.path));
    if (template.onlyInclude?.any(rel.startsWith) == false) {
      continue;
    }

    final _ = switch (file) {
      (final Directory d) => directories[rel] = d,
      (final File f) => files[rel] = f,
      _ => null,
    };
  }
}

String _relative(String dir, String path) => path.substring(dir.length + 1);

String _dotFile(String name) {
  if (name.startsWith('__')) {
    return '.${name.substring(2)}';
  }
  return name;
}

Future<void> orderImports(Directory path, Iterable<String> files) async {
  await Future.wait(
    files.map(
      (file) => _exec(
        'dart',
        path,
        ['fix', '--apply', '--code=directives_ordering', file],
      ),
    ),
  );
}

Future<void> pubGet(Directory path) async {
  await _exec('flutter', path, ['pub', 'get', '--no-example']);
}

Future<void> _exec(String exe, Directory path, List<String> arguments) async {
  final process = await Process.start(
    exe,
    arguments,
    workingDirectory: path.path,
    runInShell: true,
  );
  await process.exitCode;
}
