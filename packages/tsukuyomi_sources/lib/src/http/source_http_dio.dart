import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/src/web/mime_converter.dart'; // ignore: implementation_imports
import 'package:image/image.dart' as img show Image, encodeJpg;
import 'package:tsukuyomi_html/dom.dart';
import 'package:tsukuyomi_html/parser.dart' show parse;
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

/// 使用 Dio 作为请求器的网络漫画源
abstract class DioHttpSource extends HttpSource {
  DioHttpSource();

  late final Dio client;

  // TODO 修改唯一标识生成方式
  @override
  late final id = name.hashCode;

  @protected
  Dio newClient([Dio? client]);

  @protected
  Options buildOptions(String? method) {
    final headers = getRequestHeaders();
    const timeout = Duration(seconds: 10);
    return Options(method: method, headers: headers, sendTimeout: timeout, receiveTimeout: timeout);
  }

  @override
  dynamic parseJson(String json) {
    return jsonDecode(json);
  }

  @override
  Document parseHtml(String html) {
    return parse(html);
  }

  @override
  SourceProtoMessage parseProto(List<int> buffer, SourceProtoFields fields) {
    return SourceProtoMessage.fromBuffer(fields, buffer);
  }

  @override
  Future<dynamic> fetchJson(String url, {Dio? client, String? method}) async {
    client ??= this.client;
    final response = await client.request(url, options: buildOptions(method));
    // Dio 默认的转换器根据响应头数据可能会自动转换一次 JSON 格式数据
    return response.data is String ? parseJson(response.data) : response.data;
  }

  @override
  Future<Document> fetchHtml(String url, {Dio? client, String? method}) async {
    client ??= this.client;
    final response = await client.request(url, options: buildOptions(method));
    return parseHtml(response.data);
  }

  @override
  Future<HttpSourceBytes> fetchBytes(String url, {Dio? client, String? method}) async {
    client ??= this.client;
    final options = buildOptions(method).copyWith(responseType: ResponseType.bytes);
    final response = await client.request<List<int>>(url, options: options);
    final statusCode = response.statusCode ?? -1;
    final responseHeaders = response.headers;
    final contentTypeHeader = responseHeaders[Headers.contentTypeHeader]?.firstOrNull;
    final extension = contentTypeHeader == null ? '' : ContentType.parse(contentTypeHeader).fileExtension;
    final type = extension.startsWith('.') ? extension.substring(1, extension.length) : extension;
    return HttpSourceBytes(type: type, data: response.data!, statusCode: statusCode, responseHeaders: responseHeaders);
  }

  @override
  Future<SourceProtoMessage> fetchProto(String url, SourceProtoFields fields, {Dio? client, String? method}) async {
    client ??= this.client;
    final bytes = await fetchBytes(url, client: client, method: method);
    return parseProto(bytes.data, fields);
  }

  @override
  Future<Image> resolveImageBytes(List<int> bytes) {
    final completer = Completer<Image>();
    final imageProvider = MemoryImage(bytes is Uint8List ? bytes : Uint8List.fromList(bytes));
    // TODO 判断是否需要添加错误处理
    imageProvider.resolve(ImageConfiguration.empty).addListener(ImageStreamListener((info, synchronousCall) {
      completer.complete(info.image);
      imageProvider.evict();
    }));
    return completer.future;
  }

  @override
  Future<List<int>> encodeJpg({required Image image, required Picture picture}) async {
    // 获取图片数据
    final data = await picture.toImage(image.width, image.height);
    // 数据格式转换
    final bytes = await data.toByteData().then((data) => data!.buffer.asUint8List());
    // 创建图片对象
    final object = img.Image.fromBytes(image.width, image.height, bytes);
    // 重新编码图片
    return await compute((_) => img.encodeJpg(object, quality: 90), null);
  }
}
