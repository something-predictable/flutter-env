// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:isolate';

import 'package:riddance_env/icons.dart';
import 'package:riddance_env/pub.dart';
import 'package:riddance_env/template.dart';

void main(List<String> arguments) async {
  final path = Directory.current;
  final templatePath = await Isolate.resolvePackageUri(
    Uri.parse('package:riddance_env/template/'),
  );
  if (templatePath == null) {
    _error('Command must be run using the dart executable.');
  }
  final pubspec = await readPubspec(path);
  await copyTemplate(
    path,
    templatePath,
    [
      if (pubspec != null) Template('flutter_create', pubspec.platforms),
      const Template('overlay'),
    ],
    flutterCreateFixes(pubspec),
    pubspec?.unsupported ?? [],
    [..._legacyFiles],
  );
  if (!arguments.contains('--no-pub')) {
    await pubGet(path);
  }
  if (pubspec != null) {
    createIcons(path, pubspec.platforms);
    _createDesktop(path, pubspec);
  }
}

Never _error(String message) {
  print(message);
  exit(1);
}

Map<String, String Function(String)> flutterCreateFixes(PackageInfo? package) =>
    switch (package) {
      (final PackageInfo package) => _flutterCreateFixes(
        package,
        package.domain.split('.').reversed.join('.'),
        package.permissions.contains('internet-client'),
      ),
      null => {},
    };

Map<String, String Function(String)> _flutterCreateFixes(
  PackageInfo package,
  String org,
  bool network,
) => {
  'android/app/build.gradle.kts':
      (s) => s
          .replaceAll(
            'namespace = "xyz.k15r.riddance.flutter_create"',
            'namespace = "xyz.k15r.riddance.flutter"',
          )
          .replaceAll(
            'applicationId = "com.example.riddance.flutter_create"',
            'applicationId = "$org.${package.name}"',
          ),
  'android/app/src/main/AndroidManifest.xml':
      (s) => s
          .replaceAll(
            'android:label="flutter_create"',
            'android:label="${package.appName.replaceAll('"', '&quot;')}"',
          )
          .replaceAllIf(
            network,
            '    <application',
            '    <uses-permission android:name="android.permission.INTERNET"/>${Platform.lineTerminator}    <application',
          )
          .replaceAllIf(
            package.portrait,
            '            android:configChanges="orientation|keyboardHid',
            // ignore: lines_longer_than_80_chars
            '            android:screenOrientation="portrait"${Platform.lineTerminator}            android:configChanges="keyboardHid',
          ),
  if (network)
    'android/app/src/debug/AndroidManifest.xml':
        (s) => s.replaceFirst(
          '    <uses-permission android:name="android.permission.INTERNET"/>${Platform.lineTerminator}',
          '',
        ),
  if (network)
    'android/app/src/profile/AndroidManifest.xml':
        (s) => s.replaceFirst(
          '    <uses-permission android:name="android.permission.INTERNET"/>${Platform.lineTerminator}',
          '',
        ),
  'ios/Runner/Info.plist':
      (s) => s
          .replaceAll(
            '<string>Flutter Create</string>',
            '<string>${package.appName.replaceAll('"', '&quot;')}</string>',
          )
          .replaceAll(
            '<string>flutter_create</string>',
            '<string>${package.appName.replaceAll('"', '&quot;')}</string>',
          )
          .replaceAllIf(
            package.portrait,
            '		<string>UIInterfaceOrientationLandscapeLeft</string>${Platform.lineTerminator}',
            '',
          )
          .replaceAllIf(
            package.portrait,
            '		<string>UIInterfaceOrientationLandscapeRight</string>${Platform.lineTerminator}',
            '',
          ),
  'ios/Runner.xcodeproj':
      (s) => s.replaceAll(
        'PRODUCT_BUNDLE_IDENTIFIER = com.example.riddance.flutterCreate',
        // ignore: lines_longer_than_80_chars
        'PRODUCT_BUNDLE_IDENTIFIER = $org.${package.appName.replaceAll(' ', '')}',
      ),
  'linux/CMakeLists.txt':
      (s) => s
          .replaceAll(
            'set(BINARY_NAME "flutter_create")',
            'set(BINARY_NAME "${package.name}")',
          )
          .replaceAll(
            'set(APPLICATION_ID "com.example.riddance.flutter_create")',
            'set(APPLICATION_ID "$org.${package.name}")',
          ),
  'linux/runner/my_application.cc':
      (s) => s
          .replaceAll(
            ', "flutter_create")',
            ', "${package.appName.replaceAll('"', r'\"')}")',
          )
          .replaceAllIf(
            package.portrait,
            'window, 1280, 720',
            'window, 405, 720',
          ),
  // spell-checker: ignore xcconfig
  'macos/Runner/Configs/AppInfo.xcconfig':
      (s) => s
          .replaceAll(
            'PRODUCT_NAME = flutter_create',
            'PRODUCT_NAME = ${package.appName}',
          )
          .replaceAll(
            'PRODUCT_BUNDLE_IDENTIFIER = com.example.riddance.flutterCreate',
            // ignore: lines_longer_than_80_chars
            'PRODUCT_BUNDLE_IDENTIFIER = $org.${package.appName.replaceAll(' ', '')}',
          )
          .replaceAll(
            RegExp(
              r'Copyright © [0-9]{4} com\.example\.riddance\. All rights reserved\.',
            ),
            // ignore: lines_longer_than_80_chars
            'Copyright © ${DateTime.now().year} ${package.domain}. All rights reserved.',
          ),
  if (network)
    'macos/Runner/DebugProfile.entitlements':
        (s) => s.replaceAll(
          '\t<key>com.apple.security.app-sandbox</key>',
          '\t<key>com.apple.security.app-sandbox</key>${Platform.lineTerminator}\t<true/>${Platform.lineTerminator}\t<key>com.apple.security.network.client</key>',
        ),
  if (network)
    'macos/Runner/Release.entitlements':
        (s) => s.replaceAll(
          '\t<key>com.apple.security.app-sandbox</key>',
          '\t<key>com.apple.security.app-sandbox</key>${Platform.lineTerminator}\t<true/>${Platform.lineTerminator}\t<key>com.apple.security.network.client</key>',
        ),
  // spell-checker: ignore lproj
  if (package.portrait)
    'macos/Runner/Base.lproj/MainMenu.xib':
        (s) => s.replaceAll(
          'width="800" height="600"',
          'width="450" height="600"',
        ),
  // spell-checker: ignore xcodeproj pbxproj
  'macos/Runner.xcodeproj/project.pbxproj':
      (s) => s
          .replaceAll('flutter_create.app', '${package.appName}.app')
          .replaceAll(
            'PRODUCT_BUNDLE_IDENTIFIER = com.example.riddance.flutterCreate',
            // ignore: lines_longer_than_80_chars
            'PRODUCT_BUNDLE_IDENTIFIER = $org.${package.appName.replaceAll(' ', '')}',
          ),
  // spell-checker: ignore xcshareddata xcscheme xcschemes
  'macos/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme':
      (s) => s.replaceAll(
        'flutter_create.app',
        '${package.appName.replaceAll('"', '&quot;')}.app',
      ),
  'web/index.html':
      (s) => s
          .replaceAll(
            '<title>flutter_create</title>',
            '<title>${package.appName.replaceAll('<', '&lt;')}</title>',
          )
          .replaceAll(
            '<meta name="apple-mobile-web-app-title" content="flutter_create">',
            // ignore: lines_longer_than_80_chars
            '<meta name="apple-mobile-web-app-title" content="${package.appName.replaceAll('"', '&quot;')}">',
          )
          .replaceAll(
            '<meta name="description" content="A new Flutter project.">',
            switch (package.description) {
              (final String description) =>
                // ignore: lines_longer_than_80_chars
                '    "<meta name="description" content="${description.replaceAll('"', '&quot;')}">',
              _ => '',
            },
          ),
  'web/manifest.json':
      (s) => s
          .replaceAll(
            '"flutter_create"',
            '"${package.appName.replaceAll('"', r'\"')}"',
          )
          .replaceAll(
            '    "description": "A new Flutter project.",',
            switch (package.description) {
              (final String description) =>
                '    "description": "${description.replaceAll('"', r'\"')}",',
              _ => '',
            },
          ),
  'webos/index.html':
      (s) => s.replaceAll(
        '<title>flutter_create</title>',
        '<title>${package.appName.replaceAll('<', '&lt;')}</title>',
      ),
  'webos/appinfo.json':
      (s) => s
          .replaceAll(
            'id": "com.example.riddance.flutter_create"',
            'id": "$org.${package.name}"',
          )
          .replaceAll('version": "1.0.0"', 'version": "${package.appVersion}"')
          .replaceAll(
            'vendor": "com.example.riddance"',
            'vendor": "${package.domain.replaceAll('"', r'\"')}"',
          )
          .replaceAll(
            'title": "flutter_create"',
            'title": "${package.appName.replaceAll('"', r'\"')}"',
          ),
  'windows/CMakeLists.txt':
      (s) => s
          .replaceAll(
            'project(flutter_create LANGUAGES CXX)',
            'project(${package.name} LANGUAGES CXX)',
          )
          .replaceAll(
            'set(BINARY_NAME "flutter_create")',
            // ignore: lines_longer_than_80_chars
            'set(BINARY_NAME "${package.appName.codeUnits.every((u) => u < 127) ? package.appName.replaceAll('"', '').replaceAll(' ', '') : package.name.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ')}")',
          ),
  'windows/runner/main.cpp':
      (s) => s
          .replaceAll(
            'window.Create(L"flutter_create", ',
            // ignore: lines_longer_than_80_chars
            'window.Create(L"${package.appName.replaceAll('"', r'\"').codeUnits.map((r) => r < 128 ? String.fromCharCode(r) : '\\u${r.toRadixString(16)}').join()}", ',
          )
          .replaceAllIf(package.portrait, 'size(1280, 720)', 'size(405, 720)'),
  'windows/runner/Runner.rc':
      (s) => s
          .replaceAll(
            r'VALUE "CompanyName", "com.example.riddance" "\0"',
            'VALUE "CompanyName", "${package.domain.replaceAll('"', r'\"')}" "\\0"',
          )
          .replaceAll(
            r'VALUE "FileDescription", "flutter_create" "\0"',
            'VALUE "FileDescription", "${(package.description ?? package.appName).replaceAll('"', r'\"')}" "\\0"',
          )
          .replaceAll(
            RegExp(
              r'VALUE "LegalCopyright", "Copyright \(C\) [0-9]{4} com\.example\.riddance\. All rights reserved\." "\\0"',
            ),
            'VALUE "LegalCopyright", "Copyright © ${DateTime.now().year} ${package.domain.replaceAll('"', r'\"')}. All rights reserved." "\\0"',
          )
          .replaceAll(
            r'VALUE "OriginalFilename", "flutter_create.exe" "\0"',
            'VALUE "OriginalFilename", "${package.appName.replaceAll('"', r'\"').replaceAll(' ', '')}.exe" "\\0"',
          )
          .replaceAll(
            r'VALUE "InternalName", "flutter_create.exe" "\0"',
            'VALUE "InternalName", "${package.appName.replaceAll('"', r'\"').replaceAll(' ', '')}" "\\0"',
          )
          .replaceAll(
            r'VALUE "ProductName", "flutter_create" "\0"',
            'VALUE "ProductName", "${package.appName.replaceAll('"', r'\"')}" "\\0"',
          ),
};

void _createDesktop(Directory path, PackageInfo package) {
  if (!package.platforms.contains('linux')) {
    return;
  }
  final name =
      '${package.domain.split('.').reversed.join('.')}.${package.name}';
  File(
    [
      path.path,
      'linux',
      'freedesktop',
      'app_icon.png',
    ].join(Platform.pathSeparator),
  ).renameSync(
    [
      path.path,
      'linux',
      'freedesktop',
      '$name.png',
    ].join(Platform.pathSeparator),
  );
  File(
    [
      path.path,
      'linux',
      'freedesktop',
      '$name.desktop',
    ].join(Platform.pathSeparator),
  ).writeAsStringSync(
    [
      '[Desktop Entry]',
      'Name=${package.appName}',
      'Type=Application',
      'Terminal=false',
      if (package.description != null) 'Comment=${package.description}',
      'Exec=${package.name}',
      'Icon=$name',
      if (package.topics.isNotEmpty) 'Categories=${package.topics.join(';')};',
    ].join('\n'),
  );
}

const _legacyFiles = [
  'android/settings.gradle',
  'android/build.gradle',
  'android/app/build.gradle',
  'linux/main.cc',
  'linux/my_application.h',
  'linux/my_application.cc',
];

extension _StringEx on String {
  // ignore: avoid_positional_boolean_parameters
  String replaceAllIf(bool condition, String from, String replace) {
    if (!condition) {
      return this;
    }
    return replaceAll(from, replace);
  }
}
