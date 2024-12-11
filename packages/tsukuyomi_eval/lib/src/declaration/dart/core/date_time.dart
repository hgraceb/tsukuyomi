part of declaration.dart.core;

DartClass get _$DateTime => DartClass<DateTime>(($) => '''
class DateTime implements Comparable<DateTime> {
  // ${$.empty('DateTime.monday', () => DateTime.monday)}
  static const int monday = 1;
  // ${$.empty('DateTime.tuesday', () => DateTime.tuesday)}
  static const int tuesday = 2;
  // ${$.empty('DateTime.wednesday', () => DateTime.wednesday)}
  static const int wednesday = 3;
  // ${$.empty('DateTime.thursday', () => DateTime.thursday)}
  static const int thursday = 4;
  // ${$.empty('DateTime.friday', () => DateTime.friday)}
  static const int friday = 5;
  // ${$.empty('DateTime.saturday', () => DateTime.saturday)}
  static const int saturday = 6;
  // ${$.empty('DateTime.sunday', () => DateTime.sunday)}
  static const int sunday = 7;
  // ${$.empty('DateTime.daysPerWeek', () => DateTime.daysPerWeek)}
  static const int daysPerWeek = 7;

  // ${$.empty('DateTime.january', () => DateTime.january)}
  static const int january = 1;
  // ${$.empty('DateTime.february', () => DateTime.february)}
  static const int february = 2;
  // ${$.empty('DateTime.march', () => DateTime.march)}
  static const int march = 3;
  // ${$.empty('DateTime.april', () => DateTime.april)}
  static const int april = 4;
  // ${$.empty('DateTime.may', () => DateTime.may)}
  static const int may = 5;
  // ${$.empty('DateTime.june', () => DateTime.june)}
  static const int june = 6;
  // ${$.empty('DateTime.july', () => DateTime.july)}
  static const int july = 7;
  // ${$.empty('DateTime.august', () => DateTime.august)}
  static const int august = 8;
  // ${$.empty('DateTime.september', () => DateTime.september)}
  static const int september = 9;
  // ${$.empty('DateTime.october', () => DateTime.october)}
  static const int october = 10;
  // ${$.empty('DateTime.november', () => DateTime.november)}
  static const int november = 11;
  // ${$.empty('DateTime.december', () => DateTime.december)}
  static const int december = 12;
  // ${$.empty('DateTime.monthsPerYear', () => DateTime.monthsPerYear)}
  static const int monthsPerYear = 12;

  // ${$.debug('isUtc', ($, $$) => $.isUtc)}
  final bool isUtc;

  // ${$.empty('DateTime.new', () => DateTime.new)}
  external DateTime(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]);

  // ${$.empty('DateTime.utc', () => DateTime.utc)}
  external DateTime.utc(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]);

  // ${$.empty('DateTime.now', () => DateTime.now)}
  external DateTime.now();

  // ${$.empty('DateTime.timestamp', () => DateTime.timestamp)}
  external DateTime.timestamp();

  // ${$.empty('DateTime.parse', () => DateTime.parse)}
  external static DateTime parse(String formattedString);

  // ${$.empty('DateTime.tryParse', () => DateTime.tryParse)}
  external static DateTime? tryParse(String formattedString);

  // ${$.empty('DateTime.fromMillisecondsSinceEpoch', () => DateTime.fromMillisecondsSinceEpoch)}
  external DateTime.fromMillisecondsSinceEpoch(int millisecondsSinceEpoch, {bool isUtc = false});

  // ${$.empty('DateTime.fromMicrosecondsSinceEpoch', () => DateTime.fromMicrosecondsSinceEpoch)}
  external DateTime.fromMicrosecondsSinceEpoch(int microsecondsSinceEpoch, {bool isUtc = false});

  // ${$.debug('==', ($, $$) => $ == $$)}
  external bool operator ==(Object other);

  // ${$.debug('isBefore', ($, $$) => $.isBefore)}
  external bool isBefore(DateTime other);

  // ${$.debug('isAfter', ($, $$) => $.isAfter)}
  external bool isAfter(DateTime other);

  // ${$.debug('isAtSameMomentAs', ($, $$) => $.isAtSameMomentAs)}
  external bool isAtSameMomentAs(DateTime other);

  // ${$.debug('compareTo', ($, $$) => $.compareTo)}
  external int compareTo(DateTime other);

  // ${$.debug('hashCode', ($, $$) => $.hashCode)}
  external int get hashCode;

  // ${$.debug('toLocal', ($, $$) => $.toLocal)}
  external DateTime toLocal();

  // ${$.debug('toUtc', ($, $$) => $.toUtc)}
  external DateTime toUtc();

  // ${$.debug('toString', ($, $$) => $.toString)}
  external String toString();

  // ${$.debug('toIso8601String', ($, $$) => $.toIso8601String)}
  external String toIso8601String();

  // ${$.debug('add', ($, $$) => $.add)}
  external DateTime add(Duration duration);

  // ${$.debug('subtract', ($, $$) => $.subtract)}
  external DateTime subtract(Duration duration);

  // ${$.debug('difference', ($, $$) => $.difference)}
  external Duration difference(DateTime other);

  // ${$.debug('millisecondsSinceEpoch', ($, $$) => $.millisecondsSinceEpoch)}
  external int get millisecondsSinceEpoch;

  // ${$.debug('microsecondsSinceEpoch', ($, $$) => $.microsecondsSinceEpoch)}
  external int get microsecondsSinceEpoch;

  // ${$.debug('timeZoneName', ($, $$) => $.timeZoneName)}
  external String get timeZoneName;

  // ${$.debug('timeZoneOffset', ($, $$) => $.timeZoneOffset)}
  external Duration get timeZoneOffset;

  // ${$.debug('year', ($, $$) => $.year)}
  external int get year;

  // ${$.debug('month', ($, $$) => $.month)}
  external int get month;

  // ${$.debug('day', ($, $$) => $.day)}
  external int get day;

  // ${$.debug('hour', ($, $$) => $.hour)}
  external int get hour;

  // ${$.debug('minute', ($, $$) => $.minute)}
  external int get minute;

  // ${$.debug('second', ($, $$) => $.second)}
  external int get second;

  // ${$.debug('millisecond', ($, $$) => $.millisecond)}
  external int get millisecond;

  // ${$.debug('microsecond', ($, $$) => $.microsecond)}
  external int get microsecond;

  // ${$.debug('weekday', ($, $$) => $.weekday)}
  external int get weekday;
}
''');

DartClass get _$DateTimeCopyWith => DartClass<DateTime>(($) => '''
extension DateTimeCopyWith on DateTime {
  // ${$.debug('copyWith', ($, $$) => $.copyWith)}
  external DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
    bool? isUtc,
  });
}
''');

List<DartDeclaration> get $dateTime {
  return [
    _$DateTime,
    _$DateTimeCopyWith,
  ];
}
