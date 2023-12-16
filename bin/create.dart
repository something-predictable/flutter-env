import 'dart:io';
import 'dart:isolate';

import 'package:riddance_env/git.dart';
import 'package:riddance_env/pub.dart';
import 'package:riddance_env/template.dart';

void main(List<String> arguments) async {
  final path = Directory.current;
  await makePubspecYaml(path, arguments);
  final templatePath = await Isolate.resolvePackageUri(
    Uri.parse('package:riddance_env/template/'),
  );
  if (templatePath != null) {
    await copyTemplate(path, templatePath, ['app']);
  }
  init(path);
}
