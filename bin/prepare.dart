// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:isolate';

import 'package:riddance_env/template.dart';

void main(List<String> arguments) async {
  final templatePath = await Isolate.resolvePackageUri(
    Uri.parse('package:riddance_env/template/'),
  );
  if (templatePath == null) {
    print('Command must be run using the dart executable.');
    exit(1);
  }
  await copyTemplate(Directory.current, templatePath, [
    'flutter_create',
    'overlay',
  ]);
}
