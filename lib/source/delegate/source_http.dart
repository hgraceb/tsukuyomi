import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsukuyomi/constants/constants.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';
import 'package:tsukuyomi_html/dom.dart';
import 'package:tsukuyomi_source/tsukuyomi_source.dart';

// 使用弱引用持有漫画源对应的网络请求器，避免多次请求导致网络请求器内部包含无法通过 Isolate 传递的数据
final _clients = Expando<Dio>();

class IsolateDioHttpSource extends DioHttpSource {
  IsolateDioHttpSource({required this.delegate, required this.preferences}) {
    delegate.props['id'] ??= EvalProperty.getter(($) => id);
    delegate.props['parseJson'] ??= EvalProperty.getter(($) => parseJson);
    delegate.props['parseHtml'] ??= EvalProperty.getter(($) => parseHtml);
    delegate.props['parseProto'] ??= EvalProperty.getter(($) => parseProto);
    delegate.props['fetchJson'] ??= EvalProperty.getter(($) => fetchJson);
    delegate.props['fetchHtml'] ??= EvalProperty.getter(($) => fetchHtml);
    delegate.props['fetchBytes'] ??= EvalProperty.getter(($) => fetchBytes);
    delegate.props['fetchImageBytes'] ??= EvalProperty.getter(($) => fetchImageBytes);
    delegate.props['fetchProto'] ??= EvalProperty.getter(($) => fetchProto);
    delegate.props['setStorage'] ??= EvalProperty.getter(($) => setStorage);
    delegate.props['getStorage'] ??= EvalProperty.getter(($) => getStorage);
    delegate.props['resolveImageBytes'] ??= EvalProperty.getter(($) => resolveImageBytes);
    delegate.props['resolveStringBytes'] ??= EvalProperty.getter(($) => resolveStringBytes);
    delegate.props['encodeJpg'] ??= EvalProperty.getter(($) => encodeJpg);
    delegate.props['encodeGif'] ??= EvalProperty.getter(($) => encodeGif);
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
    final key = Keys.sourceStorage(id);
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
  Future<dynamic> fetchJson(String url, {Dio? client, String? method, Map<String, String>? headers, Object? data}) {
    // 每次请求数据时都优先创建新的网络请求器，避免多次请求导致网络请求器内部包含无法通过 Isolate 传递的数据
    return super.fetchJson(url, client: newClient(client), method: method, headers: headers, data: data);
  }

  @override
  Future<Document> fetchHtml(String url, {Dio? client, String? method, Map<String, String>? headers, Object? data}) {
    return super.fetchHtml(url, client: newClient(client), method: method, headers: headers, data: data);
  }

  @override
  Future<HttpSourceBytes> fetchBytes(String url, {Dio? client, String? method, Map<String, String>? headers, Object? data}) {
    return super.fetchBytes(url, client: newClient(client), method: method, headers: headers, data: data);
  }

  @override
  Future<SourceProtoMessage> fetchProto(
    String url,
    SourceProtoFields fields, {
    Dio? client,
    String? method,
    Map<String, String>? headers,
    Object? data
  }) {
    return super.fetchProto(url, fields, client: newClient(client), method: method, headers: headers, data: data);
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
  Future<HttpSourceMangaEntries> getMangaEntries(HttpSourceQuery query) {
    return isolate(() async => await delegate.invoke('getMangaEntries', [query]) as HttpSourceMangaEntries);
  }

  @override
  Future<HttpSourceMangaDetails> getMangaDetails(HttpSourceManga manga) {
    return isolate(() async => await delegate.invoke('getMangaDetails', [manga]) as HttpSourceMangaDetails);
  }

  @override
  Future<HttpSourceChapterImages> getChapterImages(HttpSourceChapter chapter) {
    return isolate(() async => await delegate.invoke('getChapterImages', [chapter]) as HttpSourceChapterImages);
  }

  @override
  Future<HttpSourceImageBytes> getImageBytes(HttpSourceImage image) {
    return isolate(() async => delegate.has('getImageBytes') ? await delegate.invoke('getImageBytes', [image]) : fetchImageBytes(image));
  }

  @override
  Future<HttpSourceImageBytes> getRepaintBytes(HttpSourceImageBytes bytes) async {
    return delegate.has('getRepaintBytes') ? await delegate.invoke('getRepaintBytes', [bytes]) : bytes;
  }
}
