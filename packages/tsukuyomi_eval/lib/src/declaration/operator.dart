import 'package:tsukuyomi_eval/src/property.dart';

// 参数角色来自对应的运算符声明，执行仍使用各自注册的 getter
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
