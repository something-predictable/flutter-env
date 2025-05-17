import 'dart:io';

import 'package:path/path.dart';
import 'package:riddance_env/siblings.dart';

void init(Directory path) {
  final gitPath =
      '${path.path}${Platform.pathSeparator}.git${Platform.pathSeparator}';
  if (Directory(gitPath).existsSync()) {
    return;
  }
  Directory('${gitPath}objects').createSync(recursive: true);
  Directory('${gitPath}refs').createSync(recursive: true);
  File('${gitPath}HEAD').writeAsStringSync('ref: refs/heads/main\n');
  final config = vote(path, '.git${Platform.pathSeparator}config', (content) {
    final remotes = content
        .split('[')
        .where((element) => element.startsWith('remote "origin"]'));
    if (remotes.isEmpty) {
      return null;
    }
    final replacement = remotes
        .join('[')
        .replaceAllMapped(
          _urlRegExp,
          (match) => '${match.group(1)}%${match.group(3)}',
        );
    return '[$replacement';
  });
  // spell-checker: ignore repositoryformatversion filemode logallrefupdates
  File('${gitPath}config').writeAsStringSync('''
[core]
	repositoryformatversion = 0
	filemode = false
	bare = false
	logallrefupdates = true
${config?.replaceAll('/%.git', '/${basename(path.path)}.git') ?? ''}[branch "main"]
	remote = origin
	merge = refs/heads/main''');
}

final _urlRegExp = RegExp(r'(url\s*=.*/)([^/]+)(\.git\n)');

Future<void> addAndCommit(Directory path, String message) async {
  await _gitExec(path, ['add', '.']);
  await _gitExec(path, ['commit', '-m', message]);
}

Future<void> _gitExec(Directory path, List<String> arguments) async {
  final process = await Process.start(
    'git',
    arguments,
    workingDirectory: path.path,
    runInShell: true,
  );
  await process.exitCode;
}
