import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'debug_scaffold_service.g.dart';

int _count = 0;

class DebugScaffoldService {
  DebugScaffoldService._({required this.ref});

  final DebugScaffoldServiceRef ref;

  void reset() => _count = 0;
}

@riverpod
DebugScaffoldService debugScaffoldService(DebugScaffoldServiceRef ref) {
  return DebugScaffoldService._(ref: ref);
}

@riverpod
Future<int> debugServiceCount(DebugServiceCountRef ref) async {
  return ++_count;
}
