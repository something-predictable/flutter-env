import 'dart:io';

import 'package:path/path.dart';

T? vote<T>(Directory path, String file, T Function(String content) extract) {
  final parent = dirname(path.path);
  final grouped = Directory(parent)
      .listSync()
      .where(
        (element) =>
            element.path != path.path &&
            element.statSync().type == FileSystemEntityType.directory,
      )
      .map((e) {
        try {
          return extract(File(joinAll([e.path, file])).readAsStringSync());
        } on FileSystemException catch (_) {
          return null;
        }
      })
      .fold(
        <T, int>{},
        (previousValue, element) => switch (element) {
          null => previousValue,
          final T element =>
            previousValue
              ..update(element, (value) => value + 1, ifAbsent: () => 1),
        },
      );
  if (grouped.length == 1) {
    return grouped.keys.first;
  }
  if (grouped.length > 3) {
    return null;
  }
  final top = [...grouped.entries]..sort((a, b) => b.value - a.value);
  if (top.length == 3) {
    final [first, second, third] = top;
    if (first.value > 3 && second.value == 2 && third.value == 1) {
      return first.key;
    }
    return null;
  }
  final [first, second] = top;
  if (first.value > 2 && second.value == 1) {
    return first.key;
  }
  if (first.value > 4 && second.value == 2) {
    return first.key;
  }
  return null;
}
