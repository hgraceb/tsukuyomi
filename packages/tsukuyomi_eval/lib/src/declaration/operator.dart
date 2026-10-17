import 'package:tsukuyomi_eval/src/property.dart';

// != 按 == 的规则转换参数，仍调用自己的实现
const operatorParameterSources = {'!=': '=='};

List<DartClass> get $operator {
  return [
    DartClass.operator(
      ($) => [
        $.unary('#!', ($) => $!),
        $.unary('-#', ($) => -$),
        $.unary('!#', ($) => !$),
        $.unary('~#', ($) => ~$),
        $.binary('+', ($, $$) => $ + $$),
        $.binary('-', ($, $$) => $ - $$),
        $.binary('*', ($, $$) => $ * $$),
        $.binary('/', ($, $$) => $ / $$),
        $.binary('%', ($, $$) => $ % $$),
        $.binary('~/', ($, $$) => $ ~/ $$),
        $.binary('>', ($, $$) => $ > $$),
        $.binary('<', ($, $$) => $ < $$),
        $.binary('>=', ($, $$) => $ >= $$),
        $.binary('<=', ($, $$) => $ <= $$),
        $.binary('==', ($, $$) => $ == $$),
        $.binary('!=', ($, $$) => $ != $$),
        $.binary('&', ($, $$) => $ & $$),
        $.binary('^', ($, $$) => $ ^ $$),
        $.binary('|', ($, $$) => $ | $$),
        $.binary('<<', ($, $$) => $ << $$),
        $.binary('>>', ($, $$) => $ >> $$),
        $.binary('>>>', ($, $$) => $ >>> $$),
        $.binary('[]', ($, $$) => $[$$]),
        $.ternary('[]=', ($, $$, $$$) => $[$$] = $$$),
      ],
    ),
  ];
}
