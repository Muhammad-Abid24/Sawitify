import 'package:dio/dio.dart';
import 'package:sawitify/core/network/interceptor/search_suggestion_interceptor.dart';
import 'package:sawitify/core/network/service_config.dart';

import 'interceptor/base_interceptor.dart';
import 'interceptor/error_interceptor.dart';
import 'interceptor/player_interceptor.dart';

class DioClient {
  static Dio homeDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ServiceConfig.baseUrl,
        connectTimeout: const Duration(seconds: 40),
        receiveTimeout: const Duration(seconds: 40),
        sendTimeout: const Duration(seconds: 40),
        headers: {"Content-Type": "application/json"},
      ),
    );

    dio.interceptors.addAll([
      BaseInterceptor(),
      ErrorInterceptor(),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);

    return dio;
  }

  static Dio playerDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ServiceConfig.playUrl,
        connectTimeout: const Duration(seconds: 40),
        receiveTimeout: const Duration(seconds: 40),
        sendTimeout: const Duration(seconds: 40),
        headers: {"Content-Type": "application/json"},
      ),
    );

    dio.interceptors.addAll([
      PlayerInterceptor(),
      ErrorInterceptor(),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);

    return dio;
  }

  static Dio searchSuggestionDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ServiceConfig.baseUrl,
        connectTimeout: const Duration(seconds: 40),
        receiveTimeout: const Duration(seconds: 40),
        sendTimeout: const Duration(seconds: 40),
        headers: {"Content-Type": "application/json"},
      ),
    );

    dio.interceptors.addAll([
      SearchSuggestionInterceptor(),
      ErrorInterceptor(),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);

    return dio;
  }

  static Dio searchDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ServiceConfig.baseUrl,
        connectTimeout: const Duration(seconds: 40),
        receiveTimeout: const Duration(seconds: 40),
        sendTimeout: const Duration(seconds: 40),
        headers: {"Content-Type": "application/json"},
      ),
    );

    dio.interceptors.addAll([
      SearchSuggestionInterceptor(),
      ErrorInterceptor(),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);

    return dio;
  }

  static Dio artistDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ServiceConfig.baseUrl,
        connectTimeout: const Duration(seconds: 40),
        receiveTimeout: const Duration(seconds: 40),
        sendTimeout: const Duration(seconds: 40),
        headers: {"Content-Type": "application/json"},
      ),
    );

    dio.interceptors.addAll([
      SearchSuggestionInterceptor(),
      ErrorInterceptor(),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);

    return dio;
  }
}
