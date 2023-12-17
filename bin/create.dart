import 'dart:io';
import 'dart:isolate';

import 'package:riddance_env/git.dart';
import 'package:riddance_env/pub.dart';
import 'package:riddance_env/template.dart';

void main(List<String> arguments) async {
  final path = Directory.current;
  final package = await makePubspecYaml(path, arguments);
  final templatePath = await Isolate.resolvePackageUri(
    Uri.parse('package:riddance_env/template/'),
  );
  if (templatePath != null) {
    await copyTemplate(path, templatePath, [
      'app',
    ], {
      'lib/main.dart': (contents) =>
          contents.replaceAll('flutter_create', package.name),
      'test/smoke_test.dart': (contents) =>
          contents.replaceAll('flutter_create', package.name),
    });
  }
  init(path);
}
