import 'package:flutter_test/flutter_test.dart';

Matcher println(Iterable matcher) {
  return prints('${matcher.join('\n')}\n');
}
