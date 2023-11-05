import 'dart:io';

import 'package:riddance_env/pub.dart';

void main(List<String> arguments) async {
  final path = Directory.current;
  await makePubspecYaml(path, arguments);
}
