import 'dart:io';

typedef EvalHitTest = bool Function(Object? object);

typedef EvalProperty = ({Function? getter, Function? setter});

typedef EvalDynamicProperty = (Function(dynamic), Function(dynamic, dynamic));

class Proxy<T> {
  Proxy(this.props, {Map<String, Function>? debugProps}) {
    assert(() {
      if (debugProps != null) {
        props.addAll(debugProps.map((key, value) => MapEntry(key, Never)));
      }
      return true;
    }());
  }

  final Map<String, Object> props;

  bool hitTest(Object? object) => object is T;
}

final $dynamic = Proxy<dynamic>(<String, EvalDynamicProperty>{
  'any': (($) => $.any, ($, $$) => $.any = $$),
  'cast': (($) => $.cast, ($, $$) => $.cast = $$),
  'contains': (($) => $.contains, ($, $$) => $.contains = $$),
  'elementAt': (($) => $.elementAt, ($, $$) => $.elementAt = $$),
  'every': (($) => $.every, ($, $$) => $.every = $$),
  'expand': (($) => $.expand, ($, $$) => $.expand = $$),
  'first': (($) => $.first, ($, $$) => $.first = $$),
  'firstWhere': (($) => $.firstWhere, ($, $$) => $.firstWhere = $$),
  'fold': (($) => $.fold, ($, $$) => $.fold = $$),
  'followedBy': (($) => $.followedBy, ($, $$) => $.followedBy = $$),
  'forEach': (($) => $.forEach, ($, $$) => $.forEach = $$),
  'hashCode': (($) => $.hashCode, ($, $$) => $.hashCode = $$),
  'isEmpty': (($) => $.isEmpty, ($, $$) => $.isEmpty = $$),
  'isNotEmpty': (($) => $.isNotEmpty, ($, $$) => $.isNotEmpty = $$),
  'iterator': (($) => $.iterator, ($, $$) => $.iterator = $$),
  'join': (($) => $.join, ($, $$) => $.join = $$),
  'last': (($) => $.last, ($, $$) => $.last = $$),
  'lastWhere': (($) => $.lastWhere, ($, $$) => $.lastWhere = $$),
  'length': (($) => $.length, ($, $$) => $.length = $$),
  'map': (($) => $.map, ($, $$) => $.map = $$),
  'noSuchMethod': (($) => $.noSuchMethod, ($, $$) => $.noSuchMethod = $$),
  'reduce': (($) => $.reduce, ($, $$) => $.reduce = $$),
  'runtimeType': (($) => $.runtimeType, ($, $$) => $.runtimeType = $$),
  'single': (($) => $.single, ($, $$) => $.single = $$),
  'singleWhere': (($) => $.singleWhere, ($, $$) => $.singleWhere = $$),
  'skip': (($) => $.skip, ($, $$) => $.skip = $$),
  'skipWhile': (($) => $.skipWhile, ($, $$) => $.skipWhile = $$),
  'take': (($) => $.take, ($, $$) => $.take = $$),
  'takeWhile': (($) => $.takeWhile, ($, $$) => $.takeWhile = $$),
  'toList': (($) => $.toList, ($, $$) => $.toList = $$),
  'toSet': (($) => $.toSet, ($, $$) => $.toSet = $$),
  'toString': (($) => $.toString, ($, $$) => $.toString = $$),
  'where': (($) => $.where, ($, $$) => $.where = $$),
  'whereType': (($) => $.whereType, ($, $$) => $.whereType = $$),
});

final $Object = Proxy<Object>({
  'Object.new': () => Object.new,
  'Object.hash': () => Object.hash,
  'Object.hashAll': () => Object.hashAll,
  'Object.hashAllUnordered': () => Object.hashAllUnordered,
}, debugProps: {
  'hashCode': (Object object) => object.hashCode,
  'toString': (Object object) => object.toString,
  'noSuchMethod': (Object object) => object.noSuchMethod,
  'runtimeType': (Object object) => object.runtimeType,
});

final $Iterable = Proxy<Iterable>({
  'Iterable.generate': () => Iterable.generate,
  'Iterable.empty': () => Iterable.empty,
  'Iterable.castFrom': () => Iterable.castFrom,
  'Iterable.iterableToShortString': () => Iterable.iterableToShortString,
  'Iterable.iterableToFullString': () => Iterable.iterableToFullString,
}, debugProps: {
  'iterator': (Iterable iterable) => iterable.iterator,
  'cast': (Iterable iterable) => iterable.cast,
  'followedBy': (Iterable iterable) => iterable.followedBy,
  'map': (Iterable iterable) => iterable.map,
  'where': (Iterable iterable) => iterable.where,
  'whereType': (Iterable iterable) => iterable.whereType,
  'expand': (Iterable iterable) => iterable.expand,
  'contains': (Iterable iterable) => iterable.contains,
  'forEach': (Iterable iterable) => iterable.forEach,
  'reduce': (Iterable iterable) => iterable.reduce,
  'fold': (Iterable iterable) => iterable.fold,
  'every': (Iterable iterable) => iterable.every,
  'join': (Iterable iterable) => iterable.join,
  'any': (Iterable iterable) => iterable.any,
  'toList': (Iterable iterable) => iterable.toList,
  'toSet': (Iterable iterable) => iterable.toSet,
  'length': (Iterable iterable) => iterable.length,
  'isEmpty': (Iterable iterable) => iterable.isEmpty,
  'isNotEmpty': (Iterable iterable) => iterable.isNotEmpty,
  'take': (Iterable iterable) => iterable.take,
  'takeWhile': (Iterable iterable) => iterable.takeWhile,
  'skip': (Iterable iterable) => iterable.skip,
  'skipWhile': (Iterable iterable) => iterable.skipWhile,
  'first': (Iterable iterable) => iterable.first,
  'last': (Iterable iterable) => iterable.last,
  'single': (Iterable iterable) => iterable.single,
  'firstWhere': (Iterable iterable) => iterable.firstWhere,
  'lastWhere': (Iterable iterable) => iterable.lastWhere,
  'singleWhere': (Iterable iterable) => iterable.singleWhere,
  'elementAt': (Iterable iterable) => iterable.elementAt,
  'toString': (Iterable iterable) => iterable.toString,
});

void main() {
  final props = <String, Map<EvalHitTest?, EvalProperty>>{};
  for (final proxy in [$dynamic, $Object, $Iterable]) {
    for (final entry in proxy.props.entries) {
      final key = entry.key, value = entry.value;
      late final isStatic = key.contains('.');
      late final map = props.putIfAbsent(key, () => {});
      switch (value) {
        case Function() getter:
          assert(isStatic && !map.containsKey(null));
          map[null] = (getter: getter, setter: null);
        case (final Function(dynamic) getter, final Function(dynamic, dynamic) setter):
          assert(!isStatic && !map.containsKey(null));
          map[null] = (getter: getter, setter: setter);
        case (final Function() getter, final Function(Never) setter):
          assert(isStatic && !map.containsKey(null));
          map[null] = (getter: getter, setter: setter);
        case Function(dynamic) fn:
          assert(!map.containsKey(null));
          map[null] = isStatic ? (getter: null, setter: fn) : (getter: null, setter: fn);
        case Function(Never) fn:
          assert(!map.containsKey(proxy.hitTest));
          map[proxy.hitTest] = isStatic ? (getter: null, setter: fn) : (getter: null, setter: fn);
        case Function(dynamic, dynamic) fn:
          assert(!isStatic && !map.containsKey(null));
          map[null] = (getter: null, setter: fn);
        case Function(Never, Never) fn:
          assert(!isStatic && !map.containsKey(proxy.hitTest));
          map[proxy.hitTest] = (getter: null, setter: fn);
        case Never:
          assert(props.containsKey(key), "Undefined dynamic property '$key'.");
        default:
          throw UnsupportedError("property '$key': '$value'.");
      }
    }
  }
  for (final prop in props.entries) {
    stdout.write('${prop.key.toString().padRight(30)}: ${prop.value}\n');
  }

  final iterable = List.generate(10, (i) => i);
  final getter = props['map']!.entries.first.value.getter as Function;
  final result = getter(iterable)((e) => 'v$e').toList(growable: false);
  stdout.write('${'iterable'.padRight(30)}: $iterable\n');
  stdout.write('${'result'.padRight(30)}: $result\n');
}
