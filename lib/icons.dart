import 'dart:io';

import 'package:icons_launcher/cli_commands.dart';

Future<void> createIcons(Directory path, List<String> platforms) async {
  if (!File('${path.path}${Platform.pathSeparator}icon.png').existsSync()) {
    return;
  }
  final work = Directory(
      [path.path, '.dart_tool', 'riddance_env'].join(Platform.pathSeparator));
  await work.create(recursive: true);
  final configFile = '${work.path}${Platform.pathSeparator}icons_launcher.yaml';
  File(configFile).writeAsStringSync('''
icons_launcher:
  image_path: icon.png
  platforms:
    android:
      enable: true
      adaptive_foreground_image: icon.png
      adaptive_background_color: '#000000'
    ios:
      enable: true
    web:
      enable: true
    macos:
      enable: true
    windows:
      enable: true
    linux:
      enable: true
''');
  createLauncherIcons(path: configFile);
}
