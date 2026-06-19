import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AudioOutput {
  static const _channel =
  MethodChannel(
    'audio_output',
  );

  static Future<List<dynamic>>
  getDevices() async {

    try {

      if (!Platform.isAndroid) {
        return [];
      }

      return await _channel
          .invokeMethod(
        'getDevices',
      );

    } catch (e) {

      debugPrint(
        'GET DEVICES ERROR = $e',
      );

      return [];
    }
  }

  static Future<void> show()
  async {

    try {

      if (Platform.isIOS) {

        await _channel
            .invokeMethod(

          'showIOSRoutePicker',
        );

        return;
      }

      // Android ditangani
      // langsung di Flutter

    } catch (e) {

      debugPrint(
        'AUDIO OUTPUT ERROR = $e',
      );
    }
  }

  static Future<void>
  openBluetoothSettings()
  async {

    try {

      if (
      !Platform.isAndroid
      ) {

        return;
      }

      await _channel
          .invokeMethod(

        'openBluetoothSettings',
      );

    } catch (e) {

      debugPrint(

        'BLUETOOTH ERROR = $e',
      );
    }
  }
}