import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
// import 'package:device_info_plus/device_info_plus.dart';
import 'package:device_information/device_information.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  TextEditingController _nikSapController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  String imeiNo = 'Loading...';

  @override
  void initState() {
    super.initState();
    _getDeviceInformation();
  }

  // API LOGIN
  Future<Map<String, dynamic>> _apiLogin(
      String username, String password, String manufacturer) async {
    final Uri url =
        Uri.parse('https://iksmill.app.co.id/CredentialApi/api/UserLogin');

    var request = http.MultipartRequest('POST', url);
    request.fields['UserId'] = username;
    request.fields['Password'] = password;
    request.fields['Apps'] = 'Camera_App';
    request.fields['DeviceId'] = manufacturer;

    print(manufacturer);

    try {
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        final String responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> responseData = json.decode(responseBody);

        if (responseData.containsKey('success') &&
            responseData['success'] == true) {
          return responseData['data'];
        } else {
          throw Exception('Login failed: ${responseData['message']}');
        }
      } else {
        throw Exception('Login failed');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }
  // End API LOGIN

  // GET IMEI
  Future<void> _getDeviceInformation() async {
    try {
      imeiNo = await DeviceInformation.deviceIMEINumber;
    } on PlatformException {
      imeiNo = 'Permission not access';
    }

    setState(() {});
  }
  // END IMEI

  Future<void> _handleLoginButtonPress() async {
    try {
      String username = _nikSapController.text;
      String password = _passwordController.text;

      // Dapatkan Android Device ID (IMEI)
      String manufacturer = imeiNo;
      print(manufacturer);

      // Lakukan login ke API
      Map<String, dynamic> userData =
          await _apiLogin(username, password, manufacturer);

      // Periksa apakah login berhasil berdasarkan respons API
      if (userData.isNotEmpty) {
        // Simpan status login ke SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('DeviceId', manufacturer);
        await prefs.setString('userId', username);
        await prefs.setString('name', userData['name']);
        await prefs.setString('sap', userData['sap']);
        await prefs.setString('nik', userData['nik']);

        // Hapus semua halaman kecuali halaman login dari tumpukan navigasi
        Navigator.of(context).popUntil((route) => route.isFirst);

        // Navigasi ke halaman berikutnya setelah login berhasil
        Navigator.of(context).pushReplacementNamed('/capture');
      } else {
        // Tampilkan Snackbar jika login gagal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed. Please check your credentials.'),
          ),
        );
      }
    } catch (e) {
      print('Login failed: ${e.toString()}');
      // Tampilkan Snackbar jika terjadi kesalahan saat login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.toString()}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color(0xFFED1D24)),
        automaticallyImplyLeading: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: <Widget>[
          Positioned(
            top: 0,
            // Sesuaikan dengan jarak atas yang diinginkan
            left: 0,
            right: 0,
            // bottom: 10,
            child: Image.asset(
              'assets/images/password.png',
              width: 200,
              height: 200,
            ),
          ),
          CustomPaint(
            painter: CurvedBackgroundPainter(),
            size: Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height,
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // NIK SAP
                  TextField(
                    controller: _nikSapController,
                    decoration: InputDecoration(
                      hintText: 'NIK SAP/Global ID',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 15.0, horizontal: 20.0),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    // keyboardType: TextInputType.number,
                    // inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  SizedBox(height: 10),

                  // Password
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 15.0, horizontal: 20.0),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                        child: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    obscureText: !_isPasswordVisible,
                  ),
                  SizedBox(height: 20),

                  // Button
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // handle login
                          _handleLoginButtonPress();
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Color(0xFFED1D24),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          side: BorderSide(width: 2, color: Colors.white),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CurvedBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Color(0xFFED1D24)
      ..style = PaintingStyle.fill;

    final Path path = Path()
      ..moveTo(0, size.height * 0.25)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.35,
          size.width * 0.5, size.height * 0.25)
      ..quadraticBezierTo(
          size.width * 0.75, size.height * 0.15, size.width, size.height * 0.25)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
