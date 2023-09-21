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
    _controller = CameraController(widget.camera, ResolutionPreset.max);
    _initializeCamera();
    _checkForUpdates(context);
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
          // Tombol untuk mengaktifkan/menonaktifkan autofocus
          IconButton(
            onPressed: () {
              // Toggle flash
              setState(() {
                _controller.setFlashMode(
                  _flashOn ? FlashMode.torch : FlashMode.off,
                );
                _flashOn = !_flashOn;
              });
            },
            icon: Icon(
              _flashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
          ),
          // Tombol untuk mengaktifkan/menonaktifkan autofocus
          IconButton(
            onPressed: () {
              setState(() {
                _exposureAutoMode =
                    !_exposureAutoMode; // Toggle variabel exposure
                _controller.setExposureMode(
                  _exposureAutoMode ? ExposureMode.auto : ExposureMode.locked,
                );
              });
            },
            icon: Icon(
              _exposureAutoMode ? Icons.crop_free : Icons.filter_center_focus,
              color: Colors.white,
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
      setState(() {
        _loading = true;
      });

      // Aktifkan autofocus sebelum mengambil gambar
      await _controller.setFocusMode(FocusMode.auto);

      final XFile image = await _controller.takePicture();

      final File compressedImage = await _compressImage(File(image.path));
      setState(() {
        _loading = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ImagePreviewScreen(imagePath: compressedImage.path),
        ),
      );
    } catch (e) {
      print('Error capturing image: $e');
      setState(() {
        _loading = false;
      });
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
      final maxWidth = 530;
      final maxHeight = 760;

      if (image.width > maxWidth || image.height > maxHeight) {
        final compressedImage = img.copyResize(
          image,
          width: maxWidth,
          height: maxHeight,
        );

        final compressedFile = File(imageFile.path)
          ..writeAsBytesSync(img.encodeJpg(compressedImage, quality: 98));

        return compressedFile;
      } else {
        return imageFile;
      }
    } else {
      return null;
    }
  }

  void _handleLogout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to leave?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('isLoggedIn');
                await prefs.remove('userId');
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

// ============================= Update Offline ===============================
  Future<void> _checkForUpdates(BuildContext context) async {
    final uri =
        Uri.parse('https://iksmill.app.co.id/ChecklistAPI/api/versioncamera');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as List<dynamic>;
        if (responseData.isNotEmpty) {
          final latestVersionData = responseData[0];
          final latestVersion = latestVersionData['VersionCode'];
          final currentVersion = await getAppVersion();

          if (latestVersion.compareTo(currentVersion) > 0) {
            showUpdateDialog(context, () {
              _downloadAndInstallAPK(latestVersionData['DownloadUrl']);
            });
          }
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
    await FlutterDownloader.enqueue(
      url: apkUrl,
      savedDir: externalDir!.path,
      showNotification: true,
      openFileFromNotification: true,
      saveInPublicStorage: true,
    );
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