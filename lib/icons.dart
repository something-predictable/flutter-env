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
${[if (platforms.contains('android')) '''
    android:
      enable: true
      adaptive_foreground_image: icon.png
      adaptive_background_color: '#000000'
''', if (platforms.contains('ios')) '''
    ios:
      enable: true
''', if (platforms.contains('web')) '''
    web:
      enable: true
''', if (platforms.contains('macos')) '''
    macos:
      enable: true
''', if (platforms.contains('windows')) '''
    windows:
      enable: true
''', if (platforms.contains('linux')) '''
    linux:
      enable: true
'''].join()}
''');
  createIconsLauncher(path: configFile);
  if (platforms.contains('linux')) {
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
}
