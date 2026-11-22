import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi/providers/download/download_manager_provider.dart';

void main() {
  test('Removing a task preserves the previous queue and only publishes a change when found', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final task = _Task();
    final queue = container.read(downloadQueueProvider.notifier);
    queue.addTask(task);
    final before = container.read(downloadQueueProvider);

    expect(queue.remove(task), isTrue);
    expect(before, [task]);
    final after = container.read(downloadQueueProvider);
    expect(after, isEmpty);
    expect(queue.remove(task), isFalse);
    expect(container.read(downloadQueueProvider), same(after));
  });
}

class _Task extends Fake implements DownloadTask {}
