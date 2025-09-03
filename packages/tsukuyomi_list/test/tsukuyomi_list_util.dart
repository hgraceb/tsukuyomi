import 'package:flutter_test/flutter_test.dart';

void expectList({required int length, required List<int> visible}) {
  final hidden = List.generate(length, (i) => i).toSet().difference(visible.toSet());
  for (final i in visible) {
    expect(find.text('$i'), findsOneWidget);
  }
  for (final i in hidden) {
    expect(find.text('$i'), findsNothing);
  }
}
