import 'package:http/http.dart' as http;
import 'package:xml2json/xml2json.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  TextEditingController _nikSapController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  // Service SOAP
  Future<String> _Web_Service_SOAP(String username, String password) async {
    var headers = {
      'Content-Type': 'text/xml',
    };
    var body = '''<?xml version="1.0" encoding="utf-8"?>
  <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <soap:Body>
      <CUISPassword xmlns="http://tempuri.org/">
        <sServicePassword>ITngetoP</sServicePassword>
        <sUserID>$username</sUserID>
        <sPassword>$password</sPassword>
      </CUISPassword>
    </soap:Body>
  </soap:Envelope>''';

    final response = await http.post(
      Uri.parse(
          'https://iksmill.app.co.id/wscuis/service.asmx?op=CUISPassword'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final xml2json = Xml2Json();
      xml2json.parse(response.body);
      final jsonString = xml2json.toParker();

      final jsonData = json.decode(jsonString);
      final result = jsonData['soap:Envelope']['soap:Body']
          ['CUISPasswordResponse']['CUISPasswordResult'];

      print('Result: $result');
      return result;
    } else {
      throw Exception('Login failed');
    }
  }
  // End Service SOAP

  Future<void> _handleLoginButtonPress() async {
    try {
      String userId = _nikSapController.text;

      // Melakukan login dan mendapatkan hasil respons dari SOAP
      String result = await _Web_Service_SOAP(
        _nikSapController.text,
        _passwordController.text,
      );

      if (result == 'true') {
        // Simpan status login ke SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', userId);

        print('User ID saved: $userId');

        // Hapus semua halaman kecuali halaman login dari tumpukan navigasi
        Navigator.of(context).popUntil((route) => route.isFirst);

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
