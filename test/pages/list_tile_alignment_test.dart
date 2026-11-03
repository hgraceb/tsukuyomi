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
import 'package:tsukuyomi/widgets/widgets.dart';

import '../fixtures/update_fixtures.dart';

void main() {
  for (final failed in [false, true]) {
    testWidgets(
      'Download actions stay aligned and invoke the correct operation: failed=$failed',
      (tester) async {
        final download = DatabaseDownload(source: 1, manga: 1, chapter: 10001, total: 10, progress: 4, error: failed ? 'failed' : null);
        final controller = _Downloads(download);
        final container = ProviderContainer(overrides: [downloadControllerProvider.overrideWith(() => controller)]);
        addTearDown(container.dispose);
        await _pumpPage(tester, container, const DownloadPage(), 'manga-title-1');

        final button = _alignedAction(tester, 'manga-title-1');
        expect(find.byIcon(failed ? Icons.refresh_outlined : Icons.delete_outline), findsOneWidget);
        final target = tester.getRect(button);
        await tester.tapAt(Offset(target.right - 1.0, target.center.dy));
        await tester.pump();
        expect(controller.resumed, failed ? 1 : 0);
        expect(controller.deleted, failed ? 0 : 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
      variant: TargetPlatformVariant.all(),
    );
  }

  for (final state in _ChapterState.values) {
    testWidgets(
      'Chapter actions stay aligned and preserve their behavior: $state',
      (tester) async {
        final controller = _Manga(state);
        final container = ProviderContainer(overrides: [mangaControllerProvider('1').overrideWith(() => controller)]);
        addTearDown(container.dispose);
        await _pumpPage(tester, container, const MangaPage(mangaId: '1'), 'chapter-title-1');

        final button = _alignedAction(tester, 'chapter-title-1');
        expect(tester.widget<ListTile>(find.widgetWithText(ListTile, 'chapter-title-1')).enabled, state != _ChapterState.unavailable);
        final icon = switch (state) {
          _ChapterState.available => find.byType(DownloadCircleIcon),
          _ChapterState.unavailable => find.byIcon(Icons.not_interested_outlined),
          _ChapterState.completed => find.byIcon(Icons.check_circle_outline),
          _ChapterState.failed => find.byIcon(Icons.refresh_outlined),
          _ChapterState.waiting => find.byType(AnimatedWaitingDownloadIcon),
          _ChapterState.downloading => find.byType(AnimatedProgressCircleIcon),
        };
        expect(icon, findsOneWidget);
        if (state == _ChapterState.downloading) {
          expect(tester.widget<AnimatedProgressCircleIcon>(icon).progress, 0.4);
        }
        final target = tester.getRect(button);
        await tester.tapAt(Offset(target.right - 1.0, target.center.dy));
        await tester.pump();
        expect(controller.inserted, state == _ChapterState.available ? 1 : 0);
        expect(controller.resumed, state == _ChapterState.failed ? 1 : 0);
        expect(controller.deleted, state == _ChapterState.waiting || state == _ChapterState.downloading ? 1 : 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
      variant: TargetPlatformVariant.all(),
    );
  }
}

Future<void> _pumpPage(WidgetTester tester, ProviderContainer container, Widget page, String title) async {
  final theme = TsukuyomiTheme(container.read(themePredefinedProvider).first).themeData;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: TsukuyomiLocalizations.localizationsDelegates,
        supportedLocales: TsukuyomiLocalizations.supportedLocales,
        home: page,
      ),
    ),
  );
  final row = find.widgetWithText(TsukuyomiIconButtonListTile, title);
  // 章节页有持续动画，等待列表出现即可
  for (var i = 0; i < 20 && row.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(row, findsOneWidget);
}

Finder _alignedAction(WidgetTester tester, String title) {
  final row = find.widgetWithText(ListTile, title);
  final tile = tester.widget<ListTile>(row);
  final bounds = tester.getRect(row);
  final button = find.descendant(of: row, matching: find.byType(IconButton));
  final icon = tester.getRect(find.byWidget(tester.widget<IconButton>(button).icon));
  final titleBounds = tester.getRect(find.byWidget(tile.title!));
  final subtitleBounds = tester.getRect(find.byWidget(tile.subtitle!));
  expect(titleBounds.left - bounds.left, 16.0);
  expect(bounds.right - icon.right, 16.0);
  expect(icon.left - titleBounds.right, 16.0);
  expect(icon.left - subtitleBounds.right, 16.0);
  return button;
}

class _Downloads extends DownloadController {
  _Downloads(this.download);

  final DatabaseDownload download;
  int resumed = 0;
  int deleted = 0;

  @override
  Future<DownloadState> build() async => DownloadState(
    downloads: [DownloadWithExtra(download: download, chapter: chaptersFixture(1).first, manga: mangaFixture(1))],
  );

  @override
  Future<void> resumeDownload(DatabaseDownload download) async => resumed++;

  @override
  Future<void> deleteDownload(DatabaseDownload download) async => deleted++;
}

enum _ChapterState { available, unavailable, completed, failed, waiting, downloading }

class _Manga extends MangaController {
  _Manga(this.chapterState);

  final _ChapterState chapterState;
  int resumed = 0;
  int inserted = 0;
  int deleted = 0;

  @override
  Future<MangaState> build(String mangaId) async {
    final downloading = chapterState == _ChapterState.downloading;
    final pending = downloading || chapterState == _ChapterState.waiting || chapterState == _ChapterState.failed;
    final download = DatabaseDownload(
      source: 1,
      manga: 1,
      chapter: 10001,
      total: downloading ? 10 : 0,
      progress: downloading ? 4 : 0,
      error: chapterState == _ChapterState.failed ? 'failed' : null,
    );
    return MangaState(
      source: UpdateSourceFixture(),
      manga: mangaFixture(1).copyWith(cover: ''),
      chapters: [
        MangaChapter(
          chapter: chaptersFixture(1).first.copyWith(public: chapterState != _ChapterState.unavailable),
          download: pending ? download : null,
          downloaded: chapterState == _ChapterState.completed,
          enabled: chapterState != _ChapterState.unavailable,
          downloadPercent: downloading ? 0.4 : null,
        ),
      ],
    );
  }

  @override
  Future<void> resumeDownload(DatabaseDownload download) async => resumed++;

  @override
  Future<void> insertDownload(DatabaseChapter chapter) async => inserted++;

  @override
  Future<void> deleteDownload(DatabaseDownload download) async => deleted++;
}
