import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'dart:async';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:camera_app/screens/settings_screen.dart';
import 'package:camera_app/screens/image_preview_screen.dart';
import 'package:open_file/open_file.dart';
import 'package:device_info_plus/device_info_plus.dart';

class CaptureScreen extends StatefulWidget {
  final CameraDescription camera;

  const CaptureScreen({Key? key, required this.camera}) : super(key: key);

  @override
  _CaptureScreenState createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  late CameraController _controller;
  double _baseScale = 1.0;
  double _currentZoom = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 5.0;
  bool _flashOn = false;
  bool _loading = false;
  late Directory externalDir;
  TextEditingController dirnameController = TextEditingController();
  bool _exposureAutoMode = true;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeCamera();
    _checkForUpdates(context);
    _autoLogout(context);

    // Tambahkan pemanggilan FlutterDownloader.registerCallback di sini
    FlutterDownloader.registerCallback((id, status, progress) {
      if (status == DownloadTaskStatus.complete) {
        // File APK telah diunduh dan siap untuk dibuka
        OpenFile.open(externalDir.path + '/camera_app_v0.0.6.apk');
        // Ganti dengan nama file APK Anda yang benar
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    dirnameController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    await _controller.initialize();
    if (!mounted) {
      return;
    }

    try {
      // Coba untuk mengatur mode autofocus (auto)
      await _controller.setFocusMode(FocusMode.auto);
    } catch (e) {
      // Tangani kesalahan jika mode autofocus tidak didukung
      print('Autofocus tidak didukung oleh kamera: $e');
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Container();
    }

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    final previewSize = _controller.value.previewSize!;
    final previewRatio = previewSize.height / previewSize.width;

    double screenWidth, screenHeight;

    if (deviceRatio > previewRatio) {
      screenWidth = size.width;
      screenHeight = size.width / previewSize.width * previewSize.height;
    } else {
      screenHeight = size.height;
      screenWidth = size.height / previewSize.height * previewSize.width;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.settings,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsScreen(),
              ),
            );
          },
        ),
        actions: <Widget>[
          // Tombol untuk mengaktifkan/menonaktifkan flash
          IconButton(
            onPressed: () {
              // Toggle flash
              setState(() {
                if (_flashOn) {
                  _controller.setFlashMode(FlashMode.off);
                } else {
                  _controller.setFlashMode(FlashMode.torch);
                }
                _flashOn = !_flashOn;
              });
            },
            icon: Icon(
              _flashOn ? Icons.flash_on : Icons.flash_off,
              color: _flashOn ? Colors.yellow : Colors.white,
              // Ganti warna ikon jika flash aktif
            ),
          ),

          // Tombol untuk mengaktifkan/menonaktifkan autofocus
          IconButton(
            onPressed: () {
              setState(() {
                _exposureAutoMode = !_exposureAutoMode;
                // Toggle variabel exposure
                _controller.setExposureMode(
                  _exposureAutoMode ? ExposureMode.auto : ExposureMode.locked,
                );
              });
            },
            icon: Icon(
              _exposureAutoMode ? Icons.crop_free : Icons.filter_center_focus,
              color: _exposureAutoMode ? Colors.white : Colors.yellow,
            ),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          GestureDetector(
            onScaleStart: (details) {
              _baseScale = _currentZoom;
            },
            onScaleUpdate: (details) {
              double scale = _baseScale * details.scale;
              scale = scale.clamp(
                _minAvailableZoom,
                _maxAvailableZoom,
              );
              setState(() {
                _currentZoom = scale;
                _controller.setZoomLevel(_currentZoom);
              });
            },
            child: Center(
              child: Container(
                width: screenWidth,
                height: screenHeight,
                child: CameraPreview(_controller),
              ),
            ),
          ),
          if (_loading)
            Stack(
              children: <Widget>[
                Center(
                  child: CircularProgressIndicator(),
                ),
                Center(
                  child: Text(
                    'Take pictures dont move.!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                    ),
                  ),
                ),
              ],
            ),
          Positioned(
            bottom: 80,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Zoom: ${_currentZoom.toStringAsFixed(2)}x',
                  style: TextStyle(color: Colors.white),
                ),
                Expanded(
                  child: RangeSlider(
                    values: RangeValues(_minAvailableZoom, _currentZoom),
                    min: _minAvailableZoom,
                    max: _maxAvailableZoom,
                    activeColor: Colors.white,
                    onChanged: (values) {
                      setState(() {
                        _currentZoom = values.end;
                        _controller.setZoomLevel(_currentZoom);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    _captureImage();
                  },
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.camera,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _captureImage() async {
    try {
      // Matikan terlebih dahulu flash sebelum mengambil gambar
      if (_flashOn) {
        _controller.setFlashMode(FlashMode.off);
      }

      // Aktifkan autofocus sebelum mengambil gambar
      await _controller.setFocusMode(FocusMode.auto);

      final XFile image = await _controller.takePicture();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImagePreviewScreen(imagePath: image.path),
        ),
      );
    } catch (e) {
      print('Error capturing image: $e');
    }
  }

  Future<File> _compressImage(File imageFile) async {
    final compressedImage = await _compressImageFile(imageFile);

    if (compressedImage != null) {
      return compressedImage;
    } else {
      return imageFile;
    }
  }

  Future<File?> _compressImageFile(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image != null) {
      final maxWidth = 480;
      final maxHeight = 720;

      if (image.width > maxWidth || image.height > maxHeight) {
        final compressedImage = img.copyResize(
          image,
          width: maxWidth,
          height: maxHeight,
        );

        final compressedFile = File(imageFile.path)
          ..writeAsBytesSync(img.encodeJpg(compressedImage, quality: 100));

        return compressedFile;
      } else {
        return imageFile;
      }
    } else {
      return null;
    }
  }

// ============================= Cek Device Out Logout =========================

  Future<void> _autoLogout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    // Dapatkan informasi perangkat
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    String manufacturer = androidInfo.model;

    if (userId != null && userId.isNotEmpty) {
      final url =
          Uri.parse('https://iksmill.app.co.id/CredentialApi/api/UserLogin');

      final response = await http.get(url, headers: {
        'UserId': userId,
        'Apps': 'Camera_App',
        'DeviceId': manufacturer,
      });

      if (response.statusCode == 200) {
        print('Response body: ${response.body}');
        final responseData = json.decode(response.body);
        final message = responseData['message'];

        if (message == 'Data Found') {
          // Tampilkan dialog dan lakukan logout otomatis
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Logout'),
                content: Text(
                    'Sorry, your user ID has been blocked and your session has ended.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );

          Future.delayed(Duration(seconds: 5), () {
            _handleLogout();
          });
        } else {
          print('Unknown response: $message');
        }
      } else {
        print('Request failed with status: ${response.statusCode}');
        print('Reason phrase: ${response.reasonPhrase}');
      }
    } else {
      print('User ID not found in SharedPreferences.');
    }
  }

  Future<void> _handleLogout() async {
    // Hapus data dari SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('userId');

    // Navigasi ke halaman login (ganti dengan halaman login Anda)
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      // Ganti dengan rute halaman login Anda
      (route) => false,
    );
  }
// ============================= End Cek Device Out Logout ====================

// ============================= Update Offline ===============================
  Future<void> _checkForUpdates(BuildContext context) async {
    final uri =
        Uri.parse('https://iksmill.app.co.id/CredentialApi/api/MobileVersion');

    var request = http.MultipartRequest('GET', uri);
    request.fields['apps'] = 'Camera_App';

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        final String responseBody = await response.stream.bytesToString();
        final responseData = json.decode(responseBody);

        final latestVersionData = responseData['data']['versionCode'];
        final latestVersion = latestVersionData.substring(1);
        // Menghapus karakter 'V' di awal

        final currentVersion = await getAppVersion();

        if (latestVersion.compareTo(currentVersion) > 0) {
          showUpdateDialog(context, () {
            _downloadAndInstallAPK(responseData['data']['downloadUrl']);
          });
        }
      } else {
        print('Failed to fetch data: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error during HTTP request: $error');
    }
  }

  Future<void> _downloadAndInstallAPK(String apkUrl) async {
    final externalDir = await getExternalStorageDirectory();
    final taskId = await FlutterDownloader.enqueue(
      url: apkUrl,
      savedDir: externalDir!.path,
      showNotification: true,
      openFileFromNotification: true,
      saveInPublicStorage: true,
    );

    FlutterDownloader.registerCallback((id, status, progress) {
      if (id == taskId) {
        if (status == DownloadTaskStatus.complete) {
          print('Download completed');
          showUpdateDialog(context, () {
            print('Opening and installing the APK');
            OpenFile.open(externalDir.path + '/camera_app_v0.0.6.apk');
          });
        } else if (status == DownloadTaskStatus.failed) {
          print('Download failed');
          // Handle download failure here
        }
      }
    });
  }

  Future<String> getAppVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<void> showUpdateDialog(
      BuildContext context, Function downloadAndInstallAPK) async {
    print('Before showing update dialog');

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        print('Inside dialog builder');
        return AlertDialog(
          title: Text('Update Available'),
          content: Text(
              'A new version of the app is available. Do you want to update?'),
          actions: <Widget>[
            TextButton(
              child: Text('Update'),
              onPressed: () {
                print('Update button pressed');
                downloadAndInstallAPK();
                Navigator.of(context).pop();
                print('After popping dialog');
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                print('Cancel button pressed');
                Navigator.of(context).pop();
                print('After popping dialog');
              },
            ),
          ],
        );
      },
    );

    print('After showing update dialog');
  }
}

// ============================= End Update Offline ===============================