library declaration.dio.core;

import 'package:dio/dio.dart';
import 'package:tsukuyomi_eval/tsukuyomi_eval.dart';

part 'dio_exception.dart';

part 'response.dart';

DartLibrary get dioCoreLibrary {
  return DartLibrary('dio', path: 'dio.dart', source: 'library dio;', declarations: [
    ...$dioException,
    ...$response,
  ]);
}
