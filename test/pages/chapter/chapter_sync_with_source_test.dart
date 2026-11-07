import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi/database/database.dart';
import 'package:tsukuyomi/pages/chapter/chapter_repository.dart';
import 'package:tsukuyomi/pages/chapter/providers/chapter_sync_with_source.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

import '../../fixtures/update_fixtures.dart';

const _chapter = DatabaseChapter(
  id: 1,
  manga: 1,
  index: 0,
  title: 'chapter꞉1',
  url: 'chapter-url',
  date: 'chapter-date',
  public: true,
  images: 12,
  progress: 7,
);

const _sourceChapter = HttpSourceChapter(url: 'chapter-url', name: ' chapter:1 ', date: 'chapter-date');

void main() {
  for (final rows in [
    <DatabaseChapter>[],
    [_chapter],
  ]) {
    test('Empty source leaves local chapters and associated data untouched: existing=${rows.length}', () async {
      final repository = _Chapters(rows);
      final sync = _sync(repository, UpdateSourceFixture(chapters: []));

      final result = await sync.sync();

      expect(result, const ChapterSyncResult(updateCount: 0, insertCount: 0, deleteCount: 0, sourceCount: 0));
      expect(repository.queries, 0);
      expect(repository.batches, 0);
    });
  }

  test('An unchanged chapter is not rewritten after title normalization', () async {
    final repository = _Chapters([_chapter]);

    final result = await _sync(repository).apply([_sourceChapter]);

    expect(result, const ChapterSyncResult(updateCount: 0, insertCount: 0, deleteCount: 0, sourceCount: 1));
    expect(repository.inserts, isEmpty);
    expect(repository.updates, isEmpty);
    expect(repository.deletes, isEmpty);
  });

  test('A source position change preserves reading fields and does not count as a content update', () async {
    final repository = _Chapters([_chapter.copyWith(index: 4)]);

    final result = await _sync(repository).apply([_sourceChapter]);

    expect(result, const ChapterSyncResult(updateCount: 0, insertCount: 0, deleteCount: 0, sourceCount: 1));
    final update = repository.updates.single;
    expect(update.id.value, _chapter.id);
    expect(update.index.value, 0);
    expect(update.images.present, isFalse);
    expect(update.progress.present, isFalse);
  });

  for (final (field, source, expected) in [
    ('title', const HttpSourceChapter(url: 'chapter-url', name: 'renamed', date: 'chapter-date'), _chapter.copyWith(title: 'renamed')),
    ('date', const HttpSourceChapter(url: 'chapter-url', name: 'chapter:1', date: 'new-date'), _chapter.copyWith(date: 'new-date')),
    (
      'public',
      const HttpSourceChapter(url: 'chapter-url', name: 'chapter:1', date: 'chapter-date', public: false),
      _chapter.copyWith(public: false),
    ),
  ]) {
    test('A changed $field counts once and only writes source metadata', () async {
      final repository = _Chapters([_chapter]);

      final result = await _sync(repository).apply([source]);

      expect(result, const ChapterSyncResult(updateCount: 1, insertCount: 0, deleteCount: 0, sourceCount: 1));
      final update = repository.updates.single;
      expect(update.title.value, expected.title);
      expect(update.date.value, expected.date);
      expect(update.public.value, expected.public);
      expect(update.id.value, _chapter.id);
      expect(update.index.value, 0);
      expect(update.toColumns(true).keys, unorderedEquals(['id', 'index', 'title', 'date', 'public']));
    });
  }

  test('A nonempty response still removes missing chapters and inserts new ones', () async {
    final repository = _Chapters([_chapter, _chapter.copyWith(id: 2, url: 'removed')]);
    const added = HttpSourceChapter(url: 'new-url', name: 'new', date: 'new-date');

    final result = await _sync(repository).apply([_sourceChapter, added]);

    expect(result, const ChapterSyncResult(updateCount: 0, insertCount: 1, deleteCount: 1, sourceCount: 2));
    expect(repository.deletes, [2]);
    expect(repository.inserts.single.url.value, added.url);
    expect(repository.updates, isEmpty);
  });

  test('Private chapters are valid source results and participate in synchronization', () async {
    const source = HttpSourceChapter(url: 'chapter-url', name: 'chapter:1', date: 'chapter-date', public: false);
    final repository = _Chapters([]);
    final sync = _sync(repository);

    final inserted = await sync.apply([source]);
    expect(inserted, const ChapterSyncResult(updateCount: 0, insertCount: 1, deleteCount: 0, sourceCount: 1));
    expect(repository.inserts.single.public.value, false);

    repository.rows.add(_chapter.copyWith(public: false));
    final unchanged = await sync.apply([source]);
    expect(unchanged, const ChapterSyncResult(updateCount: 0, insertCount: 0, deleteCount: 0, sourceCount: 1));
  });
}

ChapterSyncWithSource _sync(_Chapters repository, [UpdateSourceFixture? source]) {
  final container = ProviderContainer(overrides: [chapterRepositoryProvider.overrideWithValue(repository)]);
  addTearDown(container.dispose);
  return container.read(chapterSyncWithSourceProvider(source ?? UpdateSourceFixture(), mangaFixture(1)));
}

class _Chapters implements ChapterRepository {
  _Chapters(this.rows);

  final List<DatabaseChapter> rows;
  int queries = 0;
  int batches = 0;
  List<int> deletes = [];
  List<ChapterTableCompanion> inserts = [];
  List<ChapterTableCompanion> updates = [];

  @override
  Future<List<DatabaseChapter>> queryChaptersByMangaId(int mangaId) async {
    queries++;
    return rows.toList();
  }

  @override
  Future<void> batch({Iterable<int>? deletes, Iterable<ChapterTableCompanion>? inserts, Iterable<ChapterTableCompanion>? updates}) async {
    batches++;
    this.deletes = deletes?.toList() ?? [];
    this.inserts = inserts?.toList() ?? [];
    this.updates = updates?.toList() ?? [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
