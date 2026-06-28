import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'api_service.g.dart';

@RestApi()
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @POST('/browse')
  Future<dynamic> browse(
    @Body() Map<String, dynamic> body,
    @Query('alt') String alt,
    @Query('key') String apiKey,
  );

  @POST('/browse')
  Future<dynamic> browseContinuation(
    @Body() Map<String, dynamic> body,
    @Query('continuation') String continuation,
    @Query('alt') String alt,
    @Query('key') String apiKey,
  );

  @POST('/browse')
  Future<dynamic> artist(
    @Query("alt") String alt,
    @Query("key") String key,
    @Body() Map<String, dynamic> body,
  );

  @POST('/player')
  Future<dynamic> player(
    @Body() Map<String, dynamic> body,
    @Query('prettyPrint') bool prettyPrint,
  );

  @POST('/music/get_search_suggestions')
  Future<dynamic> searchSuggestion(
    @Query('alt') String alt,
    @Query('key') String key,
    @Body() Map<String, dynamic> body,
  );

  @POST('/search')
  Future<dynamic> search(
    @Query('alt') String alt,
    @Query('key') String key,
    @Body() Map<String, dynamic> body,
  );
}
