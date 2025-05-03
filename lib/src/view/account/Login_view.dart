import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../firebase/firebase_auth.dart';
import '../user/home_view.dart';
import '../store/StoreHomePage.dart';
import 'Register_view.dart';
import 'forgotPass.dart';

class Login extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<Login> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirAuth _auth = FirAuth();
  bool isChecked = false;
  bool _isLoading = false;

  static const String REMEMBER_KEY = 'remember_login';
  static const String USERNAME_KEY = 'saved_username';
  static const String PASSWORD_KEY = 'saved_password';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isChecked = prefs.getBool(REMEMBER_KEY) ?? false;
      if (isChecked) {
        _usernameController.text = prefs.getString(USERNAME_KEY) ?? '';
        _passwordController.text = prefs.getString(PASSWORD_KEY) ?? '';
      }
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (isChecked) {
      await prefs.setString(USERNAME_KEY, _usernameController.text);
      await prefs.setString(PASSWORD_KEY, _passwordController.text);
      await prefs.setBool(REMEMBER_KEY, true);
    } else {
      await prefs.remove(USERNAME_KEY);
      await prefs.remove(PASSWORD_KEY);
      await prefs.setBool(REMEMBER_KEY, false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Vui lòng nhập đầy đủ thông tin');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await _auth.signIn(
      _usernameController.text.trim(),
      _passwordController.text,
          (success, errorMessage, userCredential) async {
        if (success && userCredential != null) {
          String uid = userCredential.user!.uid;
          int position = await _auth.getUserPosition(uid);
          await _saveCredentials();

          setState(() {
            _isLoading = false;
          });

          if (position == 2) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => StoreHomePage()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => FoodHomePage()),
            );
          }
        } else {
          setState(() {
            _isLoading = false;
          });
          _showError(errorMessage ?? 'Đăng nhập thất bại');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/img/background6.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(height: 10),
                  Image.asset(
                    'assets/img/logo4.png',
                    width: 200,
                    height: 200,
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Text(
                            "Đăng nhập",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        SizedBox(height: 25),

                        // Email/username
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Email hoặc số điện thoại',
                            prefixIcon: Icon(Icons.person, color: Colors.orange),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.orange, width: 2),
                            ),
                          ),
                        ),
                        SizedBox(height: 25),

                        // Password
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: Icon(Icons.lock, color: Colors.orange),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.orange, width: 2),
                            ),
                          ),
                        ),
                        SizedBox(height: 15),

                        // Remember + Forgot password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: isChecked,
                                  activeColor: Colors.orange,
                                  onChanged: (value) {
                                    setState(() {
                                      isChecked = value!;
                                      if (!isChecked) {
                                        _saveCredentials();
                                      }
                                    });
                                  },
                                ),
                                Text("Remember"),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => Forgotpass()),
                                );
                              },
                              child: Text(
                                "Forgot Password?",
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        // Nút đăng nhập
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: _login,
                          child: Text(
                            'Đăng nhập',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        SizedBox(height: 30),

                        // Đăng ký
                        Center(
                          child: RichText(
                            text: TextSpan(
                              text: "New user? ",
                              style: TextStyle(color: Color(0xff606470), fontSize: 16),
                              children: <TextSpan>[
                                TextSpan(
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Register(),
                                        ),
                                      );
                                    },
                                  text: "Sign up for a new account",
                                  style: TextStyle(color: Color(0xff3277D8), fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 60), // thêm khoảng trống cuối trang
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}