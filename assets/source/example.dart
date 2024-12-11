import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

class TsukuyomiSource extends HttpSource {
  @override
  final String name = 'Example Source';

  @override
  final String baseUrl = 'https://example.com';

  @override
  Future<HttpSourcePage<HttpSourceManga>> getSourceMangas(HttpSourceQuery query) async {
    await Future.delayed(const Duration(seconds: 1));
    const prefix = 'Example Manga';
    return HttpSourcePage(
      next: query.page < 3,
      data: const [
        HttpSourceManga(
          name: '$prefix Sea',
          url: '16,74,176,213,218,266,381,385,404,461,477,481,516,603,609,626,640,657,715,716',
          cover: 'https://picsum.photos/id/384/800/1200',
        ),
        HttpSourceManga(
          name: '$prefix Mountain',
          url: '141,198,231,235,247,287,296,327,353,406,440,443,450,472,482,484,507,511,519,684',
          cover: 'https://picsum.photos/id/564/800/1200',
        ),
        HttpSourceManga(
          name: '$prefix Forest',
          url: '11,17,70,28,229,243,324,424,466,471,478,481,502,559,560,569,571,634,648,879',
          cover: 'https://picsum.photos/id/83/800/1200',
        ),
      ],
    );
  }

  @override
  Future<Iterable<HttpSourceChapter>> getMangaChapters(HttpSourceManga manga) async {
    await Future.delayed(const Duration(seconds: 1));
    final date = DateTime.now().toString().split('.').first;
    const prefix = 'Example Chapter';
    return List.generate(
      100,
      (index) => HttpSourceChapter(
        url: '$index,${manga.url}',
        name: '$prefix $index',
        date: date,
      ),
    ).reversed;
  }

  @override
  Future<Iterable<HttpSourceImage>> getChapterImages(HttpSourceChapter chapter) async {
    await Future.delayed(const Duration(seconds: 1));
    final ids = chapter.url.split(',').sublist(1);
    return ids.map(
      (id) => HttpSourceImage(
        url: 'https://picsum.photos/id/$id/800/1200',
      ),
    );
  }
}
