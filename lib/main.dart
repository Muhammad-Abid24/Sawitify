import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:sawitify/presentation/states/new_music_service.dart';

import '../firebase_options.dart';
import '../app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// HANYA iOS
  if (Platform.isIOS) {
    await JustAudioBackground.init(
      androidNotificationChannelId:
      'com.sawitify.audio',

      androidNotificationChannelName:
      'Sawitify',

      androidNotificationOngoing:
      true,
    );
  }

  await NewMusicService.instance
      .initialize();

  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );

}