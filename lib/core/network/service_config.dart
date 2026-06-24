import 'package:flutter_dotenv/flutter_dotenv.dart';

class ServiceConfig {
  static const baseUrl = 'https://music.youtube.com/youtubei/v1';

  static const playUrl = 'https://www.youtube.com/youtubei/v1';

  static final apiKey = dotenv.env['API_KEY'];

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'X-Youtube-Client-Name': '67',
    'X-Youtube-Client-Version': '1.20260531.06.00',
  };
}
