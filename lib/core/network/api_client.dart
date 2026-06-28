import 'package:dio/dio.dart';
import 'package:sawitify/core/network/remote/api_service.dart';
import 'package:sawitify/core/network/service_config.dart';

import 'dio_client.dart';

class ApiClient {
  late final Dio dioBrowse,
      dioPlayer,
      dioSearchSuggestion,
      dioSearch,
      dioArtist;
  late final ApiService apiBrowse,
      apiPlayer,
      apiSearchSuggestion,
      apiSearch,
      apiArtist;

  ApiClient() {
    dioBrowse = DioClient.homeDio();
    dioPlayer = DioClient.playerDio();
    dioSearchSuggestion = DioClient.searchSuggestionDio();
    dioSearch = DioClient.searchDio();
    dioArtist = DioClient.artistDio();

    apiBrowse = ApiService(dioBrowse, baseUrl: ServiceConfig.baseUrl);
    apiPlayer = ApiService(dioPlayer, baseUrl: ServiceConfig.playUrl);
    apiSearchSuggestion = ApiService(
      dioSearchSuggestion,
      baseUrl: ServiceConfig.baseUrl,
    );
    apiSearch = ApiService(dioSearch, baseUrl: ServiceConfig.baseUrl);
    apiArtist = ApiService(dioArtist, baseUrl: ServiceConfig.baseUrl);
  }
}
