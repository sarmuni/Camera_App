import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  String userName = '';
  String userNik = '';

  Future<void> _getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('name') ?? 'Unknown User';
      userNik = prefs.getString('nik') ?? 'Unknown NIK';
    });
  }

  Future<String> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? 'Unknown User';
  }

  Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FutureBuilder<String>(
            future: getUserId(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                // String userId = snapshot.data!;
                return Container(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      CircleAvatar(
                        radius: 40.0,
                        child: Icon(
                          Icons.person,
                          size: 60.0,
                          color: Colors.white,
                        ),
                        backgroundColor: Colors.red,
                      ),
                      SizedBox(width: 16.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$userNik',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$userName',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.qr_code),
                        onPressed: () {
                          // Handle QR code icon tap
                        },
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          Divider(height: 1, color: Colors.grey),

          ListTile(
            leading: Icon(Icons.security),
            title: Text('Privacy'),
            subtitle: Text('Manage your privacy settings'),
            onTap: () {
              // Navigate to privacy settings
            },
          ),
          ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('Account'),
            subtitle: Text('View and edit your account information'),
            onTap: () {
              // Navigate to account settings
            },
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('Help'),
            subtitle: Text('View Help information'),
            onTap: () {
              // Navigate to account settings
            },
          ),
          ListTile(
            leading: Icon(Icons.mobile_friendly),
            title: Text('App Version'),
            subtitle: FutureBuilder<String>(
              future: getAppVersion(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return Text('V.${snapshot.data}');
                }
              },
            ),
            onTap: () {
              // Handle tap if needed
            },
          ),

          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Log Out'),
            subtitle: Text('Log out from your account'),
            onTap: () async {
              // Menampilkan dialog konfirmasi
              bool confirmLogout = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Confirm Logout'),
                    content: Text(
                        'Are you sure you want to log out of your account?'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Batal'),
                        onPressed: () {
                          Navigator.of(context).pop(false); // Batalkan logout
                        },
                      ),
                      TextButton(
                        child: Text('Keluar'),
                        onPressed: () {
                          Navigator.of(context).pop(true); // Konfirmasi logout
                        },
                      ),
                    ],
                  );
                },
              );

              // Jika pengguna mengonfirmasi logout, maka hapus data dari SharedPreferences
              if (confirmLogout == true) {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('userId');
                await prefs.remove('isLoggedIn');
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                  // Hapus semua halaman sebelumnya
                );
              }
            },
          ),

          Spacer(), // Menggunakan Spacer untuk mengisi ruang di atas logo
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Image.asset('assets/images/logo.png'),
              width: 90.0, // Atur lebar sesuai kebutuhan
              height: 90.0, // Atur tinggi sesuai kebutuhan
            ),
          ),
        ],
      ),
    );
  }
}
