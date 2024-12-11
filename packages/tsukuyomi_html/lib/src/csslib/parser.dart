// ignore_for_file: depend_on_referenced_packages, avoid_relative_lib_imports
import 'dart:math' as math;

import 'package:source_span/source_span.dart';

import '../../csslib/lib/src/messages.dart';
import '../../csslib/lib/src/preprocessor_options.dart';
import '../../csslib/lib/visitor.dart';

export '../../csslib/lib/src/messages.dart' show Message, MessageLevel;
export '../../csslib/lib/src/preprocessor_options.dart';

part '../../csslib/lib/parser.dart';
part '../../csslib/lib/src/analyzer.dart';
part '../../csslib/lib/src/polyfill.dart';
part '../../csslib/lib/src/property.dart';
part '../../csslib/lib/src/token.dart';
part '../../csslib/lib/src/token_kind.dart';
part '../../csslib/lib/src/tokenizer.dart';
part '../../csslib/lib/src/tokenizer_base.dart';

/// [parseSelectorGroup]
SelectorGroup? tsukuyomiParseSelectorGroup(Object input, {List<Message>? errors}) {
  var source = _inputAsString(input);

  _createMessages(errors: errors);

  var file = SourceFile.fromString(source);
  return (_TsukuyomiParser(file, source)..tokenizer.inSelector = true).processSelectorGroup();
}

/// [_Parser.processPseudoSelector]
class _TsukuyomiParser extends _Parser {
  _TsukuyomiParser(super.file, super.text);

  @override
  SimpleSelector? processPseudoSelector(FileSpan start) {
    // :pseudo-class ::pseudo-element
    // TODO(terry): '::' should be token.
    _eat(TokenKind.COLON);
    var pseudoElement = _maybeEat(TokenKind.COLON);

    // TODO(terry): If no identifier specified consider optimizing out the
    //              : or :: and making this a normal selector.  For now,
    //              create an empty pseudoName.
    Identifier pseudoName;
    if (_peekIdentifier()) {
      pseudoName = identifier();
    } else {
      return null;
    }
    var name = pseudoName.name.toLowerCase();

    // Functional pseudo?
    if (_peekToken.kind == TokenKind.LPAREN) {
      if (!pseudoElement && name == 'not') {
        _eat(TokenKind.LPAREN);

        // Negation :   ':NOT(' S* negation_arg S* ')'
        var negArg = simpleSelector();

        _eat(TokenKind.RPAREN);
        return NegationSelector(negArg, _makeSpan(start));
      } else if (!pseudoElement && name == 'has') {
        // region Tsukuyomi: 优化部分常用伪类选择器解析
        _eat(TokenKind.LPAREN);
        var selector = processSelector();
        if (selector == null) {
          _errorExpected('a selector argument');
          return null;
        }
        _eat(TokenKind.RPAREN);
        var span = _makeSpan(start);
        return PseudoClassFunctionSelector(pseudoName, selector, span);
        // endregion Tsukuyomi
      } else if (!pseudoElement &&
          (name == 'host' ||
              name == 'host-context' ||
              name == 'global-context' ||
              name == '-acx-global-context')) {
        _eat(TokenKind.LPAREN);
        var selector = processCompoundSelector();
        if (selector == null) {
          _errorExpected('a selector argument');
          return null;
        }
        _eat(TokenKind.RPAREN);
        var span = _makeSpan(start);
        return PseudoClassFunctionSelector(pseudoName, selector, span);
      } else {
        // Special parsing for expressions in pseudo functions.  Minus is used
        // as operator not identifier.
        // TODO(jmesserly): we need to flip this before we eat the "(" as the
        // next token will be fetched when we do that. I think we should try to
        // refactor so we don't need this boolean; it seems fragile.
        tokenizer.inSelectorExpression = true;
        _eat(TokenKind.LPAREN);

        // Handle function expression.
        var span = _makeSpan(start);
        var expr = processSelectorExpression();

        tokenizer.inSelectorExpression = false;

        // Used during selector look-a-head if not a SelectorExpression is
        // bad.
        if (expr is SelectorExpression) {
          _eat(TokenKind.RPAREN);
          return pseudoElement
              ? PseudoElementFunctionSelector(pseudoName, expr, span)
              : PseudoClassFunctionSelector(pseudoName, expr, span);
        } else {
          _errorExpected('CSS expression');
          return null;
        }
      }
    }

    // Treat CSS2.1 pseudo-elements defined with pseudo class syntax as pseudo-
    // elements for backwards compatibility.
    return pseudoElement || _legacyPseudoElements.contains(name)
        ? PseudoElementSelector(pseudoName, _makeSpan(start),
            isLegacy: !pseudoElement)
        : PseudoClassSelector(pseudoName, _makeSpan(start));
  }
}
