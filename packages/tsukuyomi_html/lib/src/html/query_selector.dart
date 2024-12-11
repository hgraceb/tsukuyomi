// ignore_for_file: avoid_relative_lib_imports
library;

import '../../dom.dart';
import '../../html/lib/src/constants.dart' show isWhitespaceCC;
import '../csslib/parser.dart';
import '../../csslib/lib/visitor.dart';

part '../../html/lib/src/query_selector.dart';

/// [_parseSelectorList]
SelectorGroup tsukuyomiParseSelectorList(String selector) {
  final errors = <Message>[];
  final group = tsukuyomiParseSelectorGroup(selector, errors: errors);
  if (group == null || errors.isNotEmpty) {
    throw FormatException("'$selector' is not a valid selector: $errors");
  }
  return group;
}

/// [SelectorEvaluator.visitPseudoClassFunctionSelector]
class TsukuyomiSelectorEvaluator extends SelectorEvaluator {
  Element? select(Node root, Selector selector) {
    for (var element in root.nodes.whereType<Element>()) {
      _element = element;
      if (selector.visit(this) == true) return element;
      final result = select(element, selector);
      if (result != null) return result;
    }
    return null;
  }

  bool has(Selector selector) {
    final element = _element;
    final matched = element == null ? null : select(element, selector);
    _element = element;
    return matched != null;
  }

  @override
  bool visitPseudoClassFunctionSelector(PseudoClassFunctionSelector node) {
    switch (node.name) {
      case 'has':
        return has(node.selector);
    }
    return super.visitPseudoClassFunctionSelector(node);
  }
}
