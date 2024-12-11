import 'package:flutter/material.dart';
import 'package:tsukuyomi/l10n/l10n.dart';
import 'package:tsukuyomi/widgets/widgets.dart';

class CenterRetry extends StatelessWidget {
  const CenterRetry({
    super.key,
    this.message,
    required this.onRetry,
  });

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = TsukuyomiLocalizations.of(context)!;

    return Center(
      child: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(
          scrollbars: false,
          physics: const NeverScrollableScrollPhysics(),
        ),
        child: SingleChildScrollView(
          child: Column(children: [
            Text(
              message ?? l10n.loadFailed,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 24.0),
            ),
            const SizedBox(height: 12.0),
            ThrottleBuilder(
              builder: (context, throttle) => FilledButton.tonal(
                onPressed: () => throttle(onRetry),
                child: Text(l10n.retry),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
