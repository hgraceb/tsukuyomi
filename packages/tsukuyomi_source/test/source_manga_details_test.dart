import 'package:flutter_test/flutter_test.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

void main() {
  test('Content languages normalize casing, deduplicate and sort without guessing scripts', () {
    expect(normalizeMangaLanguages([' zh ', 'ZH_hans', 'pt-br', 'zh-Hans', 'JA', 'es-419', 'zh-TW', 'de-1901']), [
      'de-1901',
      'es-419',
      'ja',
      'pt-BR',
      'zh',
      'zh-Hans',
      'zh-TW',
    ]);
    expect(normalizeMangaLanguages([]), isEmpty);
    for (final value in ['chinese', '4', '', 'all', 'und', 'mul', 'zxx', 'zh--Hans', 'en-US-US']) {
      expect(() => normalizeMangaLanguages([value]), throwsFormatException, reason: value);
    }
  });

  test('Creators preserve source order and only serialize names', () {
    final creators = normalizeMangaCreators([
      const SourceMangaCreator(name: ' 甲 '),
      const SourceMangaCreator(name: '乙'),
      SourceMangaCreator.fromJson({'name': '甲'}),
    ]);
    expect(creators.map((value) => value.toJson()), [
      {'name': '甲'},
      {'name': '乙'},
    ]);
    expect(() => normalizeMangaCreators([const SourceMangaCreator(name: ' ')]), throwsFormatException);
  });

  test('Tag identity includes type and unknown classifications require explicit mapping', () {
    final tags = normalizeMangaTags([
      const SourceMangaTag(name: ' 冒险 ', type: 'Genre'),
      const SourceMangaTag(name: '冒险', type: 'genre'),
      SourceMangaTag.fromJson({'name': '冒险', 'type': 'theme'}),
    ]);
    expect(tags.map((value) => value.toJson()), [
      {'name': '冒险', 'type': 'genre'},
      {'name': '冒险', 'type': 'theme'},
    ]);
    expect(() => normalizeMangaTags([const SourceMangaTag(name: '冒险', type: 'site-category')]), throwsFormatException);
    expect(() => normalizeMangaTags([const SourceMangaTag(name: '', type: 'tag')]), throwsFormatException);
  });

  test('Status accepts fixed codes and requires source mapping for raw labels', () {
    for (final status in ['ongoing', 'completed', 'hiatus', 'cancelled', 'unknown']) {
      expect(normalizeMangaStatus(' ${status.toUpperCase()} '), status);
    }
    expect(() => normalizeMangaStatus('连载中'), throwsFormatException);
  });
}
