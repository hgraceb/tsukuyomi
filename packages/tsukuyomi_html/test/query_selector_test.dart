import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_html/parser.dart';

void main() {
  // https://github.com/dart-lang/tools/issues/1029
  test(':has()', () {
    final document = parse('''
<ul class="pagination">
  <li>
    <a>1</a>
  </li>
  <li>
    <a class="active">2</a>
  </li>
  <li>
    <a>3</a>
  </li>
</ul>
      ''');
    expect(document.querySelector('ul.pagination li:has(a.active) + li a:not(.disabled)')?.text, '3');
  });
}
