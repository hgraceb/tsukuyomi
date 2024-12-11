part of declaration.dart.core;

DartClass get _$double => DartClass<double>(($) => '''
abstract final class double extends num {
  // ${$.empty('double.nan', () => double.nan)}
  static const double nan = 0.0 / 0.0;
  // ${$.empty('double.infinity', () => double.infinity)}
  static const double infinity = 1.0 / 0.0;
  // ${$.empty('double.negativeInfinity', () => double.negativeInfinity)}
  static const double negativeInfinity = -infinity;
  // ${$.empty('double.minPositive', () => double.minPositive)}
  static const double minPositive = 5e-324;
  // ${$.empty('double.maxFinite', () => double.maxFinite)}
  static const double maxFinite = 1.7976931348623157e+308;

  // ${$.debug('remainder', ($, $$) => $.remainder)}
  double remainder(num other);

  // ${$.debug('+', ($, $$) => $ + $$)}
  double operator +(num other);

  // ${$.debug('-', ($, $$) => $ - $$)}
  double operator -(num other);

  // ${$.debug('*', ($, $$) => $ * $$)}
  double operator *(num other);

  // ${$.debug('%', ($, $$) => $ % $$)}
  double operator %(num other);

  // ${$.debug('/', ($, $$) => $ / $$)}
  double operator /(num other);

  // ${$.debug('~/', ($, $$) => $ ~/ $$)}
  int operator ~/(num other);

  // ${$.debug('-', ($, $$) => -$)}
  double operator -();

  // ${$.debug('abs', ($, $$) => $.abs)}
  double abs();

  // ${$.debug('sign', ($, $$) => $.sign)}
  double get sign;

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

  // ${$.empty('double.parse', () => double.parse)}
  external static double parse(String source);

  // ${$.empty('double.tryParse', () => double.tryParse)}
  external static double? tryParse(String source);
}
''');

List<DartDeclaration> get $double {
  return [
    _$double,
  ];
}
