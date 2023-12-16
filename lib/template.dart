import 'dart:io';

Future<void> copyTemplate(
    Directory target, Uri templatePath, List<String> templates) async {
  final directories = <String, Directory>{};
  final files = <String, File>{};
  for (final template in templates) {
    await _collect(templatePath, template, directories, files);
  }
  for (final e in directories.entries) {
    Directory(target.path + Platform.pathSeparator + e.key).createSync();
  }
  for (final e in files.entries) {
    await e.value.copy(target.path + Platform.pathSeparator + e.key);
  }
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
