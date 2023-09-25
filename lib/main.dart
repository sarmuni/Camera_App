import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:camera_app/screens/login_screen.dart';
import 'package:camera_app/screens/capture_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(
      debug: true,
      // optional: set to false to disable printing logs to console (default: true)
      ignoreSsl: false
      // option: set to false to disable working with http links (default: false)
      );

  List<CameraDescription> cameras = await availableCameras();

  final initialRoute = await _getInitialRoute();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Tempatkan FlutterDownloader.registerCallback di sini
  FlutterDownloader.registerCallback((id, status, progress) {
    if (status == DownloadTaskStatus.complete) {
      // File APK akan otomatis dibuka setelah unduhan selesai
    }
  });

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => LoginScreen(),
        '/capture': (context) => CaptureScreen(camera: cameras.first),
      },
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFED1D24),
        ),
      ),
    ),
  );
}

// Fungsi untuk mendapatkan rute awal berdasarkan status login
Future<String> _getInitialRoute() async {
  // Lakukan pemeriksaan status login di SharedPreferences atau mekanisme penyimpanan data lainnya
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  if (isLoggedIn) {
    return '/capture';
  } else {
    return '/login';
  }
}
