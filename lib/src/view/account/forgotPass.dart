import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Forgotpass extends StatefulWidget {
  @override
  State<Forgotpass> createState() => _ForgotpassState();
}

class _ForgotpassState extends State<Forgotpass> {
  final TextEditingController _emailPhoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _useEmailReset = false;
  bool _passwordResetDone = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
        backgroundColor: const Color.fromRGBO(254, 254, 253, 1.0),
        foregroundColor: Colors.orange,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/img/background6.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),
                Image.asset(
                  'assets/img/logo4.png',
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 10),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _otpVerified
                            ? "Đặt lại mật khẩu"
                            : (_otpSent ? "Nhập mã OTP" : "Quên mật khẩu"),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Nhập email hoặc sđt
                      if (!_otpSent && !_otpVerified)
                        TextField(
                          controller: _emailPhoneController,
                          decoration: const InputDecoration(
                            labelText: 'Email hoặc số điện thoại',
                            prefixIcon: Icon(Icons.email, color: Colors.orange),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.orange, width: 2),
                            ),
                          ),
                        ),

                      const SizedBox(height: 10),

                      if (!_otpSent && !_otpVerified)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ChoiceChip(
                              label: const Text("OTP"),
                              selected: !_useEmailReset,
                              onSelected: (selected) {
                                setState(() {
                                  _useEmailReset = false;
                                });
                              },
                              selectedColor: Colors.orange,
                            ),
                            const SizedBox(width: 10),
                            ChoiceChip(
                              label: const Text("Email"),
                              selected: _useEmailReset,
                              onSelected: (selected) {
                                setState(() {
                                  _useEmailReset = true;
                                });
                              },
                              selectedColor: Colors.orange,
                            ),
                          ],
                        ),

                      const SizedBox(height: 20),

                      // Nhập mã OTP
                      if (_otpSent && !_otpVerified)
                        TextField(
                          controller: _otpController,
                          decoration: const InputDecoration(
                            labelText: 'Nhập mã OTP',
                            prefixIcon: Icon(Icons.lock_clock, color: Colors.orange),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.orange, width: 2),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),

                      // Nhập mật khẩu mới
                      if (_otpVerified) ...[
                        TextField(
                          controller: _newPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Mật khẩu mới',
                            prefixIcon: Icon(Icons.lock, color: Colors.orange),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.orange, width: 2),
                            ),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _confirmPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Xác nhận mật khẩu mới',
                            prefixIcon: Icon(Icons.lock, color: Colors.orange),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.orange, width: 2),
                            ),
                          ),
                          obscureText: true,
                        ),
                      ],

                      const SizedBox(height: 30),

                      // Nút hành động chính
                      ElevatedButton(
                        onPressed: _otpVerified
                            ? _resetPassword
                            : (_otpSent
                            ? _verifyOtp
                            : (_useEmailReset ? _sendEmailReset : _sendOtp)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          _otpVerified
                              ? 'Cập nhật mật khẩu'
                              : (_otpSent
                              ? 'Xác nhận OTP'
                              : (_useEmailReset ? 'Gửi email khôi phục' : 'Gửi mã OTP')),
                        ),
                      ),

                      // Nút quay về đăng nhập
                      if (_passwordResetDone)
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.login),
                              label: const Text('Quay về đăng nhập'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendOtp() {
    if (_emailPhoneController.text.isEmpty) {
      _showSnackBar("Vui lòng nhập email hoặc số điện thoại.");
      return;
    }

    setState(() {
      _otpSent = true;
    });

    // TODO: Gửi OTP qua Firebase hoặc API ở đây
    _showSnackBar("Đã gửi mã OTP. Vui lòng kiểm tra email/điện thoại.");
  }

  void _verifyOtp() {
    if (_otpController.text != "123456") {
      _showSnackBar("Mã OTP không đúng. Vui lòng thử lại.");
    } else {
      setState(() {
        _otpVerified = true;
      });
      _showSnackBar("Xác nhận OTP thành công. Vui lòng nhập mật khẩu mới.");
    }
  }

  void _resetPassword() {
    if (_newPasswordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      _showSnackBar("Vui lòng nhập đầy đủ mật khẩu mới và xác nhận mật khẩu.");
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar("Mật khẩu xác nhận không khớp. Vui lòng kiểm tra lại.");
      return;
    }

    // TODO: Gửi yêu cầu cập nhật mật khẩu qua Firebase hoặc API ở đây
    setState(() {
      _passwordResetDone = true;
    });

    _showSnackBar("Cập nhật mật khẩu thành công!");
  }

  void _sendEmailReset() async {
    final email = _emailPhoneController.text.trim();
    if (email.isEmpty) {
      _showSnackBar("Vui lòng nhập email.");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSnackBar("Đã gửi email khôi phục mật khẩu. Vui lòng kiểm tra hộp thư.");

      // ✅ THÊM DÒNG NÀY để hiển thị nút quay về đăng nhập
      setState(() {
        _passwordResetDone = true;
      });
    } catch (e) {
      _showSnackBar("Lỗi: ${e.toString()}");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
