import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SearchSuggestionInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.baseUrl.contains('music.youtube.com')) {
      options.headers.addAll({
        'X-Goog-Visitor-ID': dotenv.env['X_GOG_VISITOR_ID'],
        'X-Origin': 'https://music.youtube.com/',
        'X-Youtube-Client-Name': '67',
        'X-Youtube-Client-Version': '1.20260603.06.00',
        'X-Youtube-Device':
            'cbr=Chrome&cbrand=apple&cbrver=81.0.4044.129&ceng=WebKit&cengver=537.36&cos=Macintosh&cosver=10_15_4&cplatform=DESKTOP',
        'X-Youtube-Page-Cl': '926051547',
        'X-Youtube-Page-Label': 'youtube.music.web.client_20260603_06_RC00',
        'X-Youtube-Utc-Offset': '-420',
        'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.129 Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Encoding': 'gzip',
        'Accept-Language': 'en-US,en;q=0.9',
        'Host': 'music.youtube.com',
      });
    }

    return handler.next(options);
  }
}
