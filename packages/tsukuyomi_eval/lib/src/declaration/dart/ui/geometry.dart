part of declaration.dart.ui;

DartClass get _$OffsetBase => DartClass<OffsetBase>(($) => '''
abstract class OffsetBase {
  final double _dx;
  final double _dy;

  const OffsetBase(this._dx, this._dy);

  // ${$.debug('isInfinite', ($, $$) => $.isInfinite)}
  external bool get isInfinite;

  // ${$.debug('isFinite', ($, $$) => $.isFinite)}
  external bool get isFinite;

  // ${$.debug('<', ($, $$) => $ < $$)}
  external bool operator <(OffsetBase other);

  // ${$.debug('<=', ($, $$) => $ <= $$)}
  external bool operator <=(OffsetBase other);

  // ${$.debug('>', ($, $$) => $ > $$)}
  external bool operator >(OffsetBase other);

  // ${$.debug('>=', ($, $$) => $ >= $$)}
  external bool operator >=(OffsetBase other);

  // ${$.debug('==', ($, $$) => $ == $$)}
  external bool operator ==(Object other);

  // ${$.debug('hashCode', ($, $$) => $.hashCode)}
  external int get hashCode;

  // ${$.debug('toString', ($, $$) => $.toString)}
  external String toString();
}
''');

DartClass get _$Offset => DartClass<Offset>(($) => '''
class Offset extends OffsetBase {
  // ${$.empty('Offset.new', () => Offset.new)}
  const Offset(super.dx, super.dy);

  // ${$.empty('Offset.fromDirection', () => Offset.fromDirection)}
  external factory Offset.fromDirection(double direction, [double distance = 1.0]);

  // ${$.debug('dx', ($, $$) => $.dx)}
  external double get dx;

  // ${$.debug('dy', ($, $$) => $.dy)}
  external double get dy;

  // ${$.debug('distance', ($, $$) => $.distance)}
  external double get distance;

  // ${$.debug('distanceSquared', ($, $$) => $.distanceSquared)}
  external double get distanceSquared;

  // ${$.debug('direction', ($, $$) => $.direction)}
  external double get direction;

  // ${$.empty('Offset.zero', () => Offset.zero)}
  static const Offset zero = Offset(0.0, 0.0);

  // ${$.empty('Offset.infinite', () => Offset.infinite)}
  static const Offset infinite = Offset(double.infinity, double.infinity);

  // ${$.debug('scale', ($, $$) => $.scale)}
  external Offset scale(double scaleX, double scaleY);

  // ${$.debug('translate', ($, $$) => $.translate)}
  external Offset translate(double translateX, double translateY);

  // ${$.debug('-', ($, $$) => -$)}
  external Offset operator -();

  // ${$.debug('-', ($, $$) => $ - $$)}
  external Offset operator -(Offset other);

  // ${$.debug('+', ($, $$) => $ + $$)}
  external Offset operator +(Offset other);

  // ${$.debug('*', ($, $$) => $ * $$)}
  external Offset operator *(double operand);

  // ${$.debug('/', ($, $$) => $ / $$)}
  external Offset operator /(double operand);

  // ${$.debug('~/', ($, $$) => $ ~/ $$)}
  external Offset operator ~/(double operand);

  // ${$.debug('%', ($, $$) => $ % $$)}
  external Offset operator %(double operand);

  // ${$.debug('&', ($, $$) => $ & $$)}
  external Rect operator &(Size other);

  // ${$.empty('Offset.lerp', () => Offset.lerp)}
  external static Offset? lerp(Offset? a, Offset? b, double t);

  // ${$.debug('==', ($, $$) => $ == $$)}
  external bool operator ==(Object other);

  // ${$.debug('hashCode', ($, $$) => $.hashCode)}
  external int get hashCode;

  // ${$.debug('toString', ($, $$) => $.toString)}
  external String toString();
}
''');

DartClass get _$Size => DartClass<Size>(($) => '''
class Size extends OffsetBase {
  // ${$.empty('Size.new', () => Size.new)}
  const Size(super.width, super.height);

  // ${$.empty('Size.copy', () => Size.copy)}
  Size.copy(Size source) : super(source.width, source.height);

  // ${$.empty('Size.square', () => Size.square)}
  const Size.square(double dimension) : super(dimension, dimension);

  // ${$.empty('Size.fromWidth', () => Size.fromWidth)}
  const Size.fromWidth(double width) : super(width, double.infinity);

  // ${$.empty('Size.fromHeight', () => Size.fromHeight)}
  const Size.fromHeight(double height) : super(double.infinity, height);

  // ${$.empty('Size.fromRadius', () => Size.fromRadius)}
  const Size.fromRadius(double radius) : super(radius * 2.0, radius * 2.0);

  // ${$.debug('width', ($, $$) => $.width)}
  external double get width;

  // ${$.debug('height', ($, $$) => $.height)}
  external double get height;

  // ${$.debug('aspectRatio', ($, $$) => $.aspectRatio)}
  external double get aspectRatio;

  // ${$.empty('Size.zero', () => Size.zero)}
  static const Size zero = Size(0.0, 0.0);

  // ${$.empty('Size.infinite', () => Size.infinite)}
  static const Size infinite = Size(double.infinity, double.infinity);

  // ${$.debug('isEmpty', ($, $$) => $.isEmpty)}
  external bool get isEmpty;

  // ${$.debug('-', ($, $$) => $ - $$)}
  external OffsetBase operator -(OffsetBase other);

  // ${$.debug('+', ($, $$) => $ + $$)}
  external Size operator +(Offset other);

  // ${$.debug('*', ($, $$) => $ * $$)}
  external Size operator *(double operand);

  // ${$.debug('/', ($, $$) => $ / $$)}
  external Size operator /(double operand);

  // ${$.debug('~/', ($, $$) => $ ~/ $$)}
  external Size operator ~/(double operand);

  // ${$.debug('%', ($, $$) => $ % $$)}
  external Size operator %(double operand);

  // ${$.debug('longestSide', ($, $$) => $.longestSide)}
  external double get shortestSide;

  // ${$.debug('longestSide', ($, $$) => $.longestSide)}
  external double get longestSide;

  // ${$.debug('topLeft', ($, $$) => $.topLeft)}
  external Offset topLeft(Offset origin);

  // ${$.debug('topCenter', ($, $$) => $.topCenter)}
  external Offset topCenter(Offset origin);

  // ${$.debug('topRight', ($, $$) => $.topRight)}
  external Offset topRight(Offset origin);

  // ${$.debug('centerLeft', ($, $$) => $.centerLeft)}
  external Offset centerLeft(Offset origin);

  // ${$.debug('center', ($, $$) => $.center)}
  external Offset center(Offset origin);

  // ${$.debug('centerRight', ($, $$) => $.centerRight)}
  external Offset centerRight(Offset origin);

  // ${$.debug('bottomLeft', ($, $$) => $.bottomLeft)}
  external Offset bottomLeft(Offset origin);

  // ${$.debug('bottomCenter', ($, $$) => $.bottomCenter)}
  external Offset bottomCenter(Offset origin);

  // ${$.debug('bottomRight', ($, $$) => $.bottomRight)}
  external Offset bottomRight(Offset origin);

  // ${$.debug('contains', ($, $$) => $.contains)}
  external bool contains(Offset offset);

  // ${$.debug('flipped', ($, $$) => $.flipped)}
  external Size get flipped;

  // ${$.empty('Size.lerp', () => Size.lerp)}
  external static Size? lerp(Size? a, Size? b, double t);

  // ${$.debug('==', ($, $$) => $ == $$)}
  external bool operator ==(Object other);

  // ${$.debug('hashCode', ($, $$) => $.hashCode)}
  external int get hashCode;

  // ${$.debug('toString', ($, $$) => $.toString)}
  external String toString();
}
''');

List<DartDeclaration> get $geometry {
  return [
    _$OffsetBase,
    _$Offset,
    _$Size,
  ];
}
