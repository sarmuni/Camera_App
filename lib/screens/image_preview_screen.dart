import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ImagePreviewScreen extends StatefulWidget {
  final String imagePath;

  ImagePreviewScreen({required this.imagePath});

  @override
  _ImagePreviewScreenState createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  final TextEditingController dirnameController = TextEditingController();
  bool _validateDirname = false;
  bool _sendingData = false; // Status mengirim data

  @override
  void initState() {
    super.initState();
    _loadDescriptionFromSharedPreferences();
    // Muat nilai dari SharedPreferences saat layar dibuat
  }

  Future<void> _loadDescriptionFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String savedDescription = prefs.getString('description') ?? '';
    setState(() {
      dirnameController.text = savedDescription;
    });
  }

  @override
  void dispose() {
    dirnameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Photo Preview'),
      ),
      body: SingleChildScrollView(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Image.file(File(widget.imagePath)),
          SizedBox(height: 16.0),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: dirnameController,
                    onChanged: (text) {
                      // Panggil fungsi untuk menyimpan deskripsi ke SharedPreferences saat teks berubah
                      _saveDescriptionToSharedPreferences(text);
                    },
                    decoration: InputDecoration(
                      hintText: 'Description',
                      border: OutlineInputBorder(),
                      labelText: 'Description',
                      errorText:
                          _validateDirname ? 'Description is required.' : null,
                    ),
                  ),
                ),
                SizedBox(width: 16.0), // Spasi antara TextField dan tombol
                SizedBox(
                  height: 48.0, // Sesuaikan tinggi dengan tinggi TextField
                  child: ElevatedButton.icon(
                    onPressed: _sendingData
                        ? null
                        : () {
                            if (dirnameController.text.isEmpty) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Validation Error'),
                                    content: Text('Description is required.'),
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
                            } else {
                              setState(() {
                                _sendingData = true;
                                // Set status mengirim data
                              });
                              // Panggil fungsi untuk mengirim foto ke server di sini
                              _sendPhotoToAPI(context, dirnameController.text);
                            }
                          },
                    icon: Icon(Icons.send),
                    label: Text('Send'),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }

  // Function untuk menyimpan deskripsi ke SharedPreferences saat teks berubah
  void _saveDescriptionToSharedPreferences(String text) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('description', text);
  }

  //=========================== Function Send To API =======================

  void _sendPhotoToAPI(BuildContext context, String dirname) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('userId') ?? '';

    // Baca file gambar sebagai bytes
    List<int> imageBytes = await File(widget.imagePath).readAsBytes();

    // Konversi bytes ke base64
    String base64Image = base64Encode(imageBytes);

    // Buat request HTTP untuk mengirim gambar ke API
    var uri = Uri.parse('https://iksmill.app.co.id/CameraApi/Api/Capture');
    var request = http.MultipartRequest('POST', uri);

    // Tambahkan base64Image sebagai bagian dari request fields
    request.fields['foto'] = base64Image;
    request.fields['userid'] = userId;
    request.fields['dirname'] = dirname;

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseText = await response.stream.bytesToString();
        print(responseText);
        _showResponseDialog(context, responseText);
      } else {
        print(response.reasonPhrase);
        _showErrorDialog(
            context, 'There was a problem with the connection or service.!');
      }
    } catch (e) {
      print('Error sending image to API: $e');
      _showErrorDialog(context,
          'Error sending image to API, There was a problem with the connection or service.!');
    } finally {
      setState(() {
        _sendingData = false; // Set status mengirim data kembali ke false
      });
    }
  }

  void _showResponseDialog(BuildContext context, String responseText) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text('The photo was successfully sent to the server.!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Failed'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
