import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi/core/core.dart';
import 'package:tsukuyomi/database/database.dart' show DatabaseChapter, DatabaseDownload;
import 'package:tsukuyomi/l10n/l10n.dart';
import 'package:tsukuyomi/pages/download/download_controller.dart';
import 'package:tsukuyomi/pages/download/download_page.dart';
import 'package:tsukuyomi/pages/download/download_repository.dart';
import 'package:tsukuyomi/pages/manga/manga_controller.dart';
import 'package:tsukuyomi/pages/manga/manga_page.dart';
import 'package:tsukuyomi/providers/theme/theme_predefined_provider.dart';

import '../fixtures/update_fixtures.dart';

void main() {
  for (final manga in [false, true]) {
    for (final density in [VisualDensity.standard, VisualDensity.compact]) {
      testWidgets(
        'List action margins and tap targets: manga=$manga, density=$density',
        (tester) async {
          for (final failed in [false, true]) {
            final download = DatabaseDownload(source: 1, manga: 1, chapter: 10001, total: 10, progress: 4, error: failed ? 'failed' : null);
            final downloads = _Downloads(download);
            final chapters = _Manga(failed ? download : null);
            final container = ProviderContainer(
              overrides: [
                downloadControllerProvider.overrideWith(() => downloads),
                mangaControllerProvider('1').overrideWith(() => chapters),
              ],
            );
            addTearDown(container.dispose);
            final theme = TsukuyomiTheme(container.read(themePredefinedProvider).first).themeData.copyWith(visualDensity: density);
            await tester.pumpWidget(
              UncontrolledProviderScope(
                container: container,
                child: MaterialApp(
                  theme: theme,
                  locale: const Locale('en'),
                  localizationsDelegates: TsukuyomiLocalizations.localizationsDelegates,
                  supportedLocales: TsukuyomiLocalizations.supportedLocales,
                  home: manga ? const MangaPage(mangaId: '1') : const DownloadPage(),
                ),
              ),
            );
            final row = find.widgetWithText(ListTile, manga ? 'chapter-title-1' : 'manga-title-1');
            // 章节页有持续动画，等待列表出现即可
            for (var i = 0; i < 20 && row.evaluate().isEmpty; i++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
            expect(row, findsOneWidget);
            final button = find.descendant(of: row, matching: find.byType(IconButton));
            final widget = tester.widget<IconButton>(button);
            final icon = find.descendant(of: button, matching: find.byWidget(widget.icon));
            final bounds = tester.getRect(row);
            final title = tester.getRect(find.text(manga ? 'chapter-title-1' : 'manga-title-1'));
            expect(title.left - bounds.left, 16.0);
            expect(bounds.right - tester.getRect(icon).right, 16.0);
            expect(tester.getSize(icon), const Size.square(24.0));
            final expectedSize = theme.materialTapTargetSize == MaterialTapTargetSize.padded ? 48.0 : 40.0;
            final target = tester.getRect(button);
            expect(target.size, Size.square(expectedSize));
            await tester.tapAt(Offset(target.right - 1.0, target.center.dy));
            await tester.pump();
            if (manga) {
              expect(failed ? chapters.resumed : chapters.inserted, 1);
            } else {
              expect(failed ? downloads.resumed : downloads.deleted, 1);
            }
            expect(find.byType(SliverSafeArea), findsNothing);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
          }
        },
        variant: TargetPlatformVariant({TargetPlatform.windows, TargetPlatform.android}),
      );
    }
  }
}

class _Downloads extends DownloadController {
  _Downloads(this.download);

  final DatabaseDownload download;
  int resumed = 0;
  int deleted = 0;

  @override
  Future<DownloadState> build() async => DownloadState(
    downloads: [
      DownloadWithExtra(download: download, chapter: chaptersFixture(1).first, manga: mangaFixture(1)),
    ],
  );

  @override
  Future<void> resumeDownload(DatabaseDownload download) async => resumed++;

  @override
  Future<void> deleteDownload(DatabaseDownload download) async => deleted++;
}

class _Manga extends MangaController {
  _Manga(this.download);

  final DatabaseDownload? download;
  int resumed = 0;
  int inserted = 0;

  @override
  Future<MangaState> build(String mangaId) async => MangaState(
    source: UpdateSourceFixture(),
    manga: mangaFixture(1).copyWith(cover: ''),
    chapters: [
      MangaChapter(chapter: chaptersFixture(1).first, download: download, downloaded: false, enabled: true, downloadPercent: null),
    ],
  );

  @override
  Future<void> resumeDownload(DatabaseDownload download) async => resumed++;

  @override
  Future<void> insertDownload(DatabaseChapter chapter) async => inserted++;
}
