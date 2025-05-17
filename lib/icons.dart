import 'dart:io';

import 'package:icons_launcher/cli_commands.dart';

void createIcons(Directory path, List<String> platforms) {
  if (!File('${path.path}${Platform.pathSeparator}icon.png').existsSync()) {
    return;
  }
  final work = Directory(
    [path.path, '.dart_tool', 'riddance_env'].join(Platform.pathSeparator),
  )..createSync(recursive: true);
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
  createIconsLauncher(path: configFile);
  final freedesktopPath = [
    path.path,
    'linux',
    'freedesktop',
  ].join(Platform.pathSeparator);
  Directory(freedesktopPath).createSync(recursive: true);
  File(
    [path.path, 'snap', 'gui', 'app_icon.png'].join(Platform.pathSeparator),
  ).renameSync('$freedesktopPath${Platform.pathSeparator}app_icon.png');
  Directory(
    '${path.path}${Platform.pathSeparator}snap',
  ).deleteSync(recursive: true);
}
