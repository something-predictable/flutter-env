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
    textStyle: const TextStyle(fontSize: 32),
    builder:
        (_, _) => Stack(
          children: [
            Center(
              child: ValueListenableBuilder(
                valueListenable: _state.count,
                builder: (_, count, _) => Text(count.toString()),
              ),
            ),
            Positioned(
              bottom: 32,
              right: 32,
              child: GestureDetector(
                onTap: _state.increment,
                child: Container(
                  width: 48,
                  height: 48,
                  color: const Color(0xFFFF9000),
                  child: const Center(child: Text('+')),
                ),
              ),
            ),
          ],
        ),
  );
}
