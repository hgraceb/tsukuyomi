import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WatchSelect<T, S> extends ConsumerStatefulWidget {
  const WatchSelect({
    super.key,
    required this.provider,
    required this.select,
    required this.builder,
  });

  final ProviderBase<T> provider;

  final Widget Function(S value) builder;

  final S Function(T initial, T current) select;

  @override
  ConsumerState<WatchSelect<T, S>> createState() => _WatchSelectState<T, S>();
}

class _WatchSelectState<T, S> extends ConsumerState<WatchSelect<T, S>> {
  late T _initial;
  late S _value;

  @override
  void initState() {
    super.initState();
    _value = ref.read(widget.provider.select(
      (next) => widget.select(_initial = next, next),
    ));
  }

  @override
  Widget build(BuildContext context) {
    _value = ref.watch(widget.provider.select(
      (next) => widget.select(_initial, next),
    ));
    return widget.builder(_value);
  }
}
