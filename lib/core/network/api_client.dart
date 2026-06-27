import 'package:dio/dio.dart';
import 'package:sawitify/core/network/remote/api_service.dart';
import 'package:sawitify/core/network/service_config.dart';

import 'dio_client.dart';

class ApiClient {
  late final Dio dioBrowse, dioPlayer, dioSearch, dioArtist;
  late final ApiService apiBrowse, apiPlayer, apiSearch, apiArtist;

  ApiClient() {
    dioBrowse = DioClient.homeDio();
    dioPlayer = DioClient.playerDio();
    dioSearch = DioClient.searchDio();
    dioArtist = DioClient.artistDio();

    apiBrowse = ApiService(dioBrowse, baseUrl: ServiceConfig.baseUrl);
    apiPlayer = ApiService(dioPlayer, baseUrl: ServiceConfig.playUrl);
    apiSearch = ApiService(dioSearch, baseUrl: ServiceConfig.baseUrl);
    apiArtist = ApiService(dioArtist, baseUrl: ServiceConfig.baseUrl);
  }
}
