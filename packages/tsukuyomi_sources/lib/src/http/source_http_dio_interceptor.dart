import 'package:dio/dio.dart';
import 'package:tsukuyomi_sources/tsukuyomi_sources.dart';

/// 最大请求重试次数限制
const _kRetryCountRetries = 1;

/// 自定义重试次数请求头
const _kRetryCountHeader = 'x-retry-count';

/// 拦截器继续执行下一阶段
typedef InterceptorNext = void Function();

/// 拦截器直接返回最终结果
typedef InterceptorResolve = void Function(Response response);

/// 拦截器直接返回最终错误
typedef InterceptorReject = void Function(DioException error);

/// 使用 Dio 作为请求器的网络漫画源重试拦截器
class DioHttpSourceInterceptor extends Interceptor {
  DioHttpSourceInterceptor(this.dio, this.getReplaceHeaders);

  /// 网络的请求器
  final Dio dio;

  /// 请求重试方法
  final Future<Map<String, String>> Function(HttpSourceResponse response) getReplaceHeaders;

  /// 发送重试请求
  Future<void>? _retryRequest({
    required InterceptorNext next,
    required InterceptorResolve resolve,
    required InterceptorReject reject,
    required RequestOptions requestOptions,
    Response? response,
    DioException? error,
  }) async {
    try {
      // 如果请求已经被外部取消了
      if (requestOptions.cancelToken?.isCancelled ?? false) return next();
      // 获取当前请求重试的总次数
      final retryCount = requestOptions.headers[_kRetryCountHeader] ?? 0;
      // 限制请求重试次数的最大值
      if (retryCount >= _kRetryCountRetries) return next();

      // 获取请求重试需要的新数据
      final oldResponse = HttpSourceResponse(error: error, code: response?.statusCode, data: response?.data);
      final newHeaders = await getReplaceHeaders(oldResponse);

      // 判断是否需要发送重试请求
      if (newHeaders.isEmpty) return next();
      final headers = {...requestOptions.headers, ...newHeaders, _kRetryCountHeader: retryCount + 1};
      resolve(await dio.fetch(requestOptions.copyWith(headers: headers)));
    } on DioException catch (e) {
      reject(e);
    } catch (error, stackTrace) {
      reject(DioException(requestOptions: requestOptions, message: "Retry '${requestOptions.uri}'.", error: error, stackTrace: stackTrace));
    }
  }

  @override
  Future<void> onResponse(Response response, ResponseInterceptorHandler handler) async {
    await _retryRequest(
      next: () => handler.next(response),
      resolve: (response) => handler.resolve(response),
      reject: (error) => handler.reject(error),
      requestOptions: response.requestOptions,
      response: response,
    );
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    await _retryRequest(
      next: () => handler.next(err),
      resolve: (response) => handler.resolve(response),
      reject: (error) => handler.reject(error),
      requestOptions: err.requestOptions,
      response: err.response,
      error: err,
    );
  }
}
