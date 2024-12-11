part of declaration.dart.core;

DartClass get _$num => DartClass<num>(($) => '''
sealed class num implements Comparable<num> {
  // ${$.debug('==', ($, $$) => $ == $$)}
  bool operator ==(Object other);

  // ${$.debug('hashCode', ($, $$) => $.hashCode)}
  int get hashCode;

  // ${$.debug('compareTo', ($, $$) => $.compareTo)}
  int compareTo(num other);

  // ${$.debug('+', ($, $$) => $ + $$)}
  num operator +(num other);

  // ${$.debug('-', ($, $$) => $ - $$)}
  num operator -(num other);

  // ${$.debug('*', ($, $$) => $ * $$)}
  num operator *(num other);

  // ${$.debug('%', ($, $$) => $ % $$)}
  num operator %(num other);

  // ${$.debug('/', ($, $$) => $ / $$)}
  double operator /(num other);

  // ${$.debug('~/', ($, $$) => $ ~/ $$)}
  int operator ~/(num other);

  // ${$.debug('-', ($, $$) => -$)}
  num operator -();

  // ${$.debug('remainder', ($, $$) => $.remainder)}
  num remainder(num other);

  // ${$.debug('<', ($, $$) => $ < $$)}
  bool operator <(num other);

  // ${$.debug('<=', ($, $$) => $ <= $$)}
  bool operator <=(num other);

  // ${$.debug('>', ($, $$) => $ > $$)}
  bool operator >(num other);

  // ${$.debug('>=', ($, $$) => $ >= $$)}
  bool operator >=(num other);

  // ${$.debug('isNaN', ($, $$) => $.isNaN)}
  bool get isNaN;

  // ${$.debug('isNegative', ($, $$) => $.isNegative)}
  bool get isNegative;

  // ${$.debug('isInfinite', ($, $$) => $.isInfinite)}
  bool get isInfinite;

  // ${$.debug('isFinite', ($, $$) => $.isFinite)}
  bool get isFinite;

  // ${$.debug('abs', ($, $$) => $.abs)}
  num abs();

  // ${$.debug('sign', ($, $$) => $.sign)}
  num get sign;

  // ${$.debug('round', ($, $$) => $.round)}
  int round();

  // ${$.debug('floor', ($, $$) => $.floor)}
  int floor();

  // ${$.debug('ceil', ($, $$) => $.ceil)}
  int ceil();

  // ${$.debug('truncate', ($, $$) => $.truncate)}
  int truncate();

  // ${$.debug('roundToDouble', ($, $$) => $.roundToDouble)}
  double roundToDouble();

  // ${$.debug('floorToDouble', ($, $$) => $.floorToDouble)}
  double floorToDouble();

  // ${$.debug('ceilToDouble', ($, $$) => $.ceilToDouble)}
  double ceilToDouble();

  // ${$.debug('truncateToDouble', ($, $$) => $.truncateToDouble)}
  double truncateToDouble();

  // ${$.debug('clamp', ($, $$) => $.clamp)}
  num clamp(num lowerLimit, num upperLimit);

  // ${$.debug('toInt', ($, $$) => $.toInt)}
  int toInt();

  // ${$.debug('toDouble', ($, $$) => $.toDouble)}
  double toDouble();

  // ${$.debug('toStringAsFixed', ($, $$) => $.toStringAsFixed)}
  String toStringAsFixed(int fractionDigits);

  // ${$.debug('toStringAsExponential', ($, $$) => $.toStringAsExponential)}
  String toStringAsExponential([int? fractionDigits]);

  // ${$.debug('toStringAsPrecision', ($, $$) => $.toStringAsPrecision)}
  String toStringAsPrecision(int precision);

  // ${$.debug('toString', ($, $$) => $.toString)}
  String toString();

  // ${$.empty('num.parse', () => num.parse)}
  external static num parse(String input);

  // ${$.empty('num.tryParse', () => num.tryParse)}
  external static num? tryParse(String input);
}
''');

List<DartDeclaration> get $num {
  return [
    _$num,
  ];
}
