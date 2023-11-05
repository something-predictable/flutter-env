import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

void main() {
  final state = State();
  runApp(App(state));
}

final class State {
  final _count = ValueNotifier(0);

  ValueListenable<int> get count => _count;

  void increment() {
    ++_count.value;
  }
}

final class App extends StatelessWidget {
  const App(this.state, {super.key});

  final State state;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          ValueListenableBuilder(
            valueListenable: state.count,
            builder: (_, count, __) => Text(count.toString()),
          ),
          GestureDetector(
            onTap: state.increment,
            child: const SizedBox.square(dimension: 48, child: Text('+')),
          ),
        ],
      );
}
