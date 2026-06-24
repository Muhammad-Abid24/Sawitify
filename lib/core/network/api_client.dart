import 'package:dio/dio.dart';
import 'package:sawitify/core/network/remote/api_service.dart';
import 'package:sawitify/core/network/service_config.dart';

import 'dio_client.dart';

class ApiClient {
  late final Dio dioBrowse, dioPlayer;
  late final ApiService apiBrowse, apiPlayer;

  ApiClient() {
    dioBrowse = DioClient.homeDio();
    dioPlayer = DioClient.playerDio();

    apiBrowse = ApiService(dioBrowse, baseUrl: ServiceConfig.baseUrl);
    apiPlayer = ApiService(dioPlayer, baseUrl: ServiceConfig.playUrl);
  }
}
