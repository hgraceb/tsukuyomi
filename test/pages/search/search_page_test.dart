import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi/database/database.dart' show DatabaseSource;
import 'package:tsukuyomi/l10n/l10n.dart';
import 'package:tsukuyomi/pages/search/search_page.dart';
import 'package:tsukuyomi/pages/source/source_service.dart';
import 'package:tsukuyomi/providers/platform/platform_metadata_provider.dart';
import 'package:tsukuyomi/source/source.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

void main() {
  testWidgets('An empty first page and a failed request have distinct, actionable retry buttons', (tester) async {
    const installed = DatabaseSource(id: 1, name: 'Example', source: '');
    final source = _SearchSource(installed.id);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyboardVisibleProvider.overrideWithValue(false),
          statusBarHeightProvider.overrideWithValue(0),
          sourcesStreamProvider.overrideWith((ref) => Stream.value([installed])),
          sourceByIdProvider(installed.id).overrideWith((ref) async => source),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: TsukuyomiLocalizations.localizationsDelegates,
          supportedLocales: TsukuyomiLocalizations.supportedLocales,
          home: SearchPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'example');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    final empty = find.widgetWithIcon(IconButton, Icons.search_off_outlined);
    expect(find.textContaining('No search results'), findsOneWidget);
    expect(tester.widget<IconButton>(empty).tooltip, 'Retry');
    expect(tester.widget<IconButton>(empty).color, isNull);
    source.error = StateError('offline');
    await tester.tap(empty);
    await tester.pumpAndSettle();

    final failed = find.widgetWithIcon(IconButton, Icons.refresh_outlined);
    expect(find.textContaining('offline'), findsOneWidget);
    expect(tester.widget<IconButton>(failed).color, Theme.of(tester.element(failed)).colorScheme.error);
    source.error = null;
    await tester.tap(failed);
    await tester.pumpAndSettle();
    expect(empty, findsOneWidget);
  });
}

class _SearchSource extends NoInstalledSource {
  _SearchSource(super.id);

  Object? error;

  @override
  Future<HttpSourceMangaEntries> getMangaEntries(SourceQuery query) async {
    if (error case final error?) throw error;
    return HttpSourceMangaEntries(mangas: []);
  }
}
