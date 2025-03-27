import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../firebase/firebase_auth.dart';
import '../home_view.dart';
import '../StoreHomePage.dart';
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

  // Keys for SharedPreferences
  static const String REMEMBER_KEY = 'remember_login';
  static const String USERNAME_KEY = 'saved_username';
  static const String PASSWORD_KEY = 'saved_password';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  // Load saved credentials when app starts
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

  // Save credentials
  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (isChecked) {
      await prefs.setString(USERNAME_KEY, _usernameController.text);
      await prefs.setString(PASSWORD_KEY, _passwordController.text);
      await prefs.setBool(REMEMBER_KEY, true);
    } else {
      // Clear saved credentials if remember is unchecked
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

          // Gọi Firebase để lấy position
          int position = await _auth.getUserPosition(uid);

          // Lưu thông tin đăng nhập nếu remember được bật
          await _saveCredentials();

          setState(() {
            _isLoading = false;
          });

          // Điều hướng theo position
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
  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Forgotpass()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng nhập'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/img/background(1).jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/img/logo1.jpg',
                    width: 400,
                    height: 300,
                  ),
                  SizedBox(height: 20.0),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Email hoặc số điện thoại',
                      filled: true,
                      fillColor: Colors.orangeAccent[100],
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: Colors.orange, width: 2.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: Colors.orange, width: 3.0),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.0),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      filled: true,
                      fillColor: Colors.orangeAccent[100],
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: Colors.orange, width: 2.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: Colors.orange, width: 3.0),
                      ),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: Text("Remember"),
                          value: isChecked,
                          onChanged: (newValue) {
                            setState(() {
                              isChecked = newValue!;
                              if (!isChecked) {
                                // Clear saved credentials when unchecked
                                _saveCredentials();
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Forgotpass()),
                          );
                        },
                        child: Text("Forgot Password?"),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                      MaterialStateProperty.resolveWith<Color>((states) {
                        return Colors.orange;
                      }),
                      foregroundColor:
                      MaterialStateProperty.resolveWith<Color>((states) {
                        return Colors.white;
                      }),
                    ),
                    onPressed: _login,
                    child: Text('Đăng nhập'),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),
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
                            style:
                            TextStyle(color: Color(0xff3277D8), fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(),
              ),
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
