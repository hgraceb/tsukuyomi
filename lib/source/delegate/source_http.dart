import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';
import 'package:tsukuyomi_html/dom.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

extension on Iterable {
  /// 类型强转后使用 toList 避免 Iterable 的闭包可能捕获无法通过 Isolate 传递的数据
  Iterable<T> castList<T>() {
    assert(<dynamic>[] is! List<T>, T);
    return cast<T>().toList();
  }
}

extension on HttpSourcePage {
  HttpSourcePage<HttpSourceManga> castMangaPage() {
    return HttpSourcePage(
      next: next,
      data: data.cast<HttpSourceManga>(),
    );
  }
}

// 使用弱引用持有漫画源对应的网络请求器，避免多次请求导致网络请求器内部包含无法通过 Isolate 传递的数据
final _clients = Expando<Dio>();

class IsolateDioHttpSource extends DioHttpSource {
  IsolateDioHttpSource({required this.delegate, required this.preferences}) {
    delegate.clazz.props['id'] ??= EvalProperty.getter(($) => id);
    delegate.clazz.props['parseJson'] ??= EvalProperty.getter(($) => parseJson);
    delegate.clazz.props['parseHtml'] ??= EvalProperty.getter(($) => parseHtml);
    delegate.clazz.props['fetchJson'] ??= EvalProperty.getter(($) => fetchJson);
    delegate.clazz.props['fetchHtml'] ??= EvalProperty.getter(($) => fetchHtml);
    delegate.clazz.props['fetchBytes'] ??= EvalProperty.getter(($) => fetchBytes);
    delegate.clazz.props['fetchProto'] ??= EvalProperty.getter(($) => fetchProto);
    delegate.clazz.props['setStorage'] ??= EvalProperty.getter(($) => setStorage);
    delegate.clazz.props['getStorage'] ??= EvalProperty.getter(($) => getStorage);
    delegate.clazz.props['resolveImageBytes'] ??= EvalProperty.getter(($) => resolveImageBytes);
    delegate.clazz.props['encodeJpg'] ??= EvalProperty.getter(($) => encodeJpg);
  }

  final ObjInstance delegate;

  final SharedPreferences preferences;

  final Map<String, String> storage = {};

  final Isolate mainIsolate = Isolate.current;

  late final options = BaseOptions(baseUrl: baseUrl);

  @override
  late final name = delegate.get('name');

  @override
  late final baseUrl = delegate.get('baseUrl');

  @override
  Dio get client => _clients[this] ??= newClient();

  @protected
  Future<T> isolate<T>(FutureOr<T> Function() callback) async {
    if (mainIsolate != Isolate.current) return await callback();
    // TODO 错误处理和多线程处理（避免同时调用时数据被覆盖）
    final key = 'source.$id';
    final value = preferences.getString(key) ?? '{}';
    storage.clear();
    storage.addAll(jsonDecode(value).cast<String, String>());
    final result = await compute((_) async => (await callback(), storage), null);
    await preferences.setString(key, jsonEncode(result.$2));
    return result.$1;
  }

  @override
  Dio newClient([Dio? client]) {
    final newClient = client ?? Dio(options);
    if (delegate.has('getReplaceHeaders')) newClient.interceptors.add(DioHttpSourceInterceptor(newClient, getReplaceHeaders));
    return newClient;
  }

  @override
  Future<dynamic> fetchJson(String url, [Dio? client]) {
    // 每次请求数据时都优先创建新的网络请求器，避免多次请求导致网络请求器内部包含无法通过 Isolate 传递的数据
    return super.fetchJson(url, newClient(client));
  }

  @override
  Future<Document> fetchHtml(String url, [Dio? client]) {
    return super.fetchHtml(url, newClient(client));
  }

  @override
  Future<HttpSourceBytes> fetchBytes(String url, [Dio? client]) {
    return super.fetchBytes(url, newClient(client));
  }

  @override
  String setStorage(String key, String value) {
    return storage[key] = value;
  }

  @override
  String? getStorage(String key, String? defaultValue) {
    return storage.containsKey(key) ? storage[key] : defaultValue;
  }

  @override
  Map<String, String> getRequestHeaders() {
    return delegate.has('getRequestHeaders') ? delegate.invoke('getRequestHeaders', null) : const {};
  }

  @override
  Future<Map<String, String>> getReplaceHeaders(HttpSourceResponse response) {
    return isolate(() async => await delegate.invoke('getReplaceHeaders', [response]));
  }

  @override
  Future<HttpSourcePage<HttpSourceManga>> getSourceMangas(HttpSourceQuery query) {
    // TODO 解释器优化类型自动转换后删除多余的 as 和 cast 语句
    return isolate(() async => (await delegate.invoke('getSourceMangas', [query]) as HttpSourcePage).castMangaPage());
  }

  @override
  Future<Iterable<HttpSourceChapter>> getMangaChapters(HttpSourceManga manga) {
    return isolate(() async => (await delegate.invoke('getMangaChapters', [manga]) as Iterable).castList<HttpSourceChapter>());
  }

  @override
  Future<Iterable<HttpSourceImage>> getChapterImages(HttpSourceChapter chapter) {
    return isolate(() async => (await delegate.invoke('getChapterImages', [chapter]) as Iterable).castList<HttpSourceImage>());
  }

  @override
  Future<HttpSourceBytes> getImageBytes(HttpSourceImage image) {
    return isolate(() async => delegate.has('getImageBytes') ? await delegate.invoke('getImageBytes', [image]) : fetchBytes(image.url));
  }

  @override
  Future<HttpSourceBytes> getRepaintBytes(HttpSourceBytes bytes) async {
    return delegate.has('getRepaintBytes') ? await delegate.invoke('getRepaintBytes', [bytes]) : bytes;
  }
}
