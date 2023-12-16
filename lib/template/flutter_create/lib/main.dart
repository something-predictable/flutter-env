import 'package:flutter/widgets.dart';
import 'package:flutter_create/state.dart';

void main() {
  final state = AppState();
  runApp(App(state));
}

final class App extends StatelessWidget {
  const App(this._state, {super.key});

  final AppState _state;

  @override
  Widget build(BuildContext context) => WidgetsApp(
        color: const Color(0xFFFF9000),
        builder: (_, __) => Column(
          children: [
            ValueListenableBuilder(
              valueListenable: _state.count,
              builder: (_, count, __) => Text(count.toString()),
            ),
            GestureDetector(
              onTap: _state.increment,
              child: const SizedBox.square(dimension: 48, child: Text('+')),
            ),
          ],
        ),
      );
}
