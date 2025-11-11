import 'package:tsukuyomi_html/dom.dart';
import 'package:tsukuyomi_html/src/html/query_selector.dart' as html;
import 'package:tsukuyomi_html/src/html/query_selector.dart';

/// [html.matches]
bool matches(Element node, String selector) {
  return TsukuyomiSelectorEvaluator().matches(node, tsukuyomiParseSelectorList(selector));
}

/// [html.querySelector]
Element? querySelector(Node node, String selector) {
  return TsukuyomiSelectorEvaluator().querySelector(node, tsukuyomiParseSelectorList(selector));
}

/// [html.querySelectorAll]
List<Element> querySelectorAll(Node node, String selector) {
  final results = <Element>[];
  TsukuyomiSelectorEvaluator().querySelectorAll(node, tsukuyomiParseSelectorList(selector), results);
  return results;
}
