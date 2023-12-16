import 'package:flutter/foundation.dart';

final class AppState {
  final _count = ValueNotifier(0);

  ValueListenable<int> get count => _count;

  void increment() {
    ++_count.value;
  }
}
