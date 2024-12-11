void main() {
  final list = [1, '2', 3, '4'];
  print('${list.where((e) => e is! num)}'); // (2, 4)
  print('${Function.apply(list.where, [(e) => e is! num])}'); // (2, 4)
  print('${list.whereType<String>()}'); // (2, 4)
  print('${Function.apply(list.whereType, [])}'); // (1, 2, 3, 4)
  print('${Function.apply(list.whereType<String>, [])}'); // (2, 4)
}
