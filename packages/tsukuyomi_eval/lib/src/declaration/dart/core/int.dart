part of declaration.dart.core;

DartClass get _$int => DartClass<int>(($) => '''
abstract final class int extends num {
  // ${$.empty('int.fromEnvironment', () => throw EvalPermissionError('int.fromEnvironment'))}
  external const factory int.fromEnvironment(String name, {int defaultValue});

  // ${$.debug('&', ($, $$) => $ & $$)}
  int operator &(int other);

  // ${$.debug('|', ($, $$) => $ | $$)}
  int operator |(int other);

  // ${$.debug('^', ($, $$) => $ ^ $$)}
  int operator ^(int other);

  // ${$.debug('~#', ($, $$) => ~$)}
  int operator ~();

  // ${$.debug('<<', ($, $$) => $ << $$)}
  int operator <<(int shiftAmount);

  // ${$.debug('>>', ($, $$) => $ >> $$)}
  int operator >>(int shiftAmount);

  // ${$.debug('>>>', ($, $$) => $ >>> $$)}
  int operator >>>(int shiftAmount);

  // ${$.debug('modPow', ($, $$) => $.modPow)}
  int modPow(int exponent, int modulus);

  // ${$.debug('modInverse', ($, $$) => $.modInverse)}
  int modInverse(int modulus);

  // ${$.debug('gcd', ($, $$) => $.gcd)}
  int gcd(int other);

  // ${$.debug('isEven', ($, $$) => $.isEven)}
  bool get isEven;

  // ${$.debug('isOdd', ($, $$) => $.isOdd)}
  bool get isOdd;

  // ${$.debug('bitLength', ($, $$) => $.bitLength)}
  int get bitLength;

  // ${$.debug('toUnsigned', ($, $$) => $.toUnsigned)}
  int toUnsigned(int width);

  // ${$.debug('toSigned', ($, $$) => $.toSigned)}
  int toSigned(int width);

  // ${$.debug('-', ($, $$) => -$)}
  int operator -();

  // ${$.debug('abs', ($, $$) => $.abs)}
  int abs();

  // ${$.debug('sign', ($, $$) => $.sign)}
  int get sign;

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

  // ${$.debug('toString', ($, $$) => $.toString)}
  String toString();

  // ${$.debug('toRadixString', ($, $$) => $.toRadixString)}
  String toRadixString(int radix);

  // ${$.empty('int.parse', () => int.parse)}
  external static int parse(String source, {int? radix});

  // ${$.empty('int.tryParse', () => int.tryParse)}
  external static int? tryParse(String source, {int? radix});
}
''');

List<DartDeclaration> get $int {
  return [
    _$int,
  ];
}
