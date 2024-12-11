part of declaration.dart.core;

DartClass get _$Duration => DartClass<Duration>(($) => '''
class Duration implements Comparable<Duration> {
  // ${$.empty('Duration.microsecondsPerMillisecond', () => Duration.microsecondsPerMillisecond)}
  static const int microsecondsPerMillisecond = 1000;

  // ${$.empty('Duration.millisecondsPerSecond', () => Duration.millisecondsPerSecond)}
  static const int millisecondsPerSecond = 1000;

  // ${$.empty('Duration.secondsPerMinute', () => Duration.secondsPerMinute)}
  static const int secondsPerMinute = 60;

  // ${$.empty('Duration.minutesPerHour', () => Duration.minutesPerHour)}
  static const int minutesPerHour = 60;

  // ${$.empty('Duration.hoursPerDay', () => Duration.hoursPerDay)}
  static const int hoursPerDay = 24;

  // ${$.empty('Duration.microsecondsPerSecond', () => Duration.microsecondsPerSecond)}
  static const int microsecondsPerSecond = microsecondsPerMillisecond * millisecondsPerSecond;

  // ${$.empty('Duration.microsecondsPerMinute', () => Duration.microsecondsPerMinute)}
  static const int microsecondsPerMinute = microsecondsPerSecond * secondsPerMinute;

  // ${$.empty('Duration.microsecondsPerHour', () => Duration.microsecondsPerHour)}
  static const int microsecondsPerHour = microsecondsPerMinute * minutesPerHour;

  // ${$.empty('Duration.microsecondsPerDay', () => Duration.microsecondsPerDay)}
  static const int microsecondsPerDay = microsecondsPerHour * hoursPerDay;

  // ${$.empty('Duration.millisecondsPerMinute', () => Duration.millisecondsPerMinute)}
  static const int millisecondsPerMinute = millisecondsPerSecond * secondsPerMinute;

  // ${$.empty('Duration.millisecondsPerHour', () => Duration.millisecondsPerHour)}
  static const int millisecondsPerHour = millisecondsPerMinute * minutesPerHour;

  // ${$.empty('Duration.millisecondsPerDay', () => Duration.millisecondsPerDay)}
  static const int millisecondsPerDay = millisecondsPerHour * hoursPerDay;

  // ${$.empty('Duration.secondsPerHour', () => Duration.secondsPerHour)}
  static const int secondsPerHour = secondsPerMinute * minutesPerHour;

  // ${$.empty('Duration.secondsPerDay', () => Duration.secondsPerDay)}
  static const int secondsPerDay = secondsPerHour * hoursPerDay;

  // ${$.empty('Duration.minutesPerDay', () => Duration.minutesPerDay)}
  static const int minutesPerDay = minutesPerHour * hoursPerDay;

  // ${$.empty('Duration.zero', () => Duration.zero)}
  static const Duration zero = Duration(seconds: 0);

  // ${$.empty('Duration.new', () => Duration.new)}
  external const Duration({
    int days = 0,
    int hours = 0,
    int minutes = 0,
    int seconds = 0,
    int milliseconds = 0,
    int microseconds = 0,
  });

  // ${$.debug('+', ($, $$) => $ + $$)}
  external Duration operator +(Duration other);

  // ${$.debug('-', ($, $$) => $ - $$)}
  external Duration operator -(Duration other);

  // ${$.debug('*', ($, $$) => $ * $$)}
  external Duration operator *(num factor);

  // ${$.debug('~/', ($, $$) => $ ~/ $$)}
  external Duration operator ~/(int quotient);

  // ${$.debug('<', ($, $$) => $ < $$)}
  external bool operator <(Duration other);

  // ${$.debug('>', ($, $$) => $ > $$)}
  external bool operator >(Duration other);

  // ${$.debug('<=', ($, $$) => $ <= $$)}
  external bool operator <=(Duration other);

  // ${$.debug('>=', ($, $$) => $ >= $$)}
  external bool operator >=(Duration other);

  // ${$.debug('inDays', ($, $$) => $.inDays)}
  external int get inDays;

  // ${$.debug('inHours', ($, $$) => $.inHours)}
  external int get inHours;

  // ${$.debug('inMinutes', ($, $$) => $.inMinutes)}
  external int get inMinutes;

  // ${$.debug('inSeconds', ($, $$) => $.inSeconds)}
  external int get inSeconds;

  // ${$.debug('inMilliseconds', ($, $$) => $.inMilliseconds)}
  external int get inMilliseconds;

  // ${$.debug('inMicroseconds', ($, $$) => $.inMicroseconds)}
  external int get inMicroseconds;

  // ${$.debug('==', ($, $$) => $ == $$)}
  external bool operator ==(Object other);

  // ${$.debug('hashCode', ($, $$) => $.hashCode)}
  external int get hashCode;

  // ${$.debug('compareTo', ($, $$) => $.compareTo)}
  external int compareTo(Duration other);

  // ${$.debug('toString', ($, $$) => $.toString)}
  external String toString();

  // ${$.debug('isNegative', ($, $$) => $.isNegative)}
  external bool get isNegative;

  // ${$.debug('abs', ($, $$) => $.abs)}
  external Duration abs();

  // ${$.debug('-', ($, $$) => -$)}
  external Duration operator -();
}
''');

List<DartDeclaration> get $duration {
  return [
    _$Duration,
  ];
}
