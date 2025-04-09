import 'package:flutter/material.dart';

class Forgotpass extends StatefulWidget {
  @override
  State<Forgotpass> createState() => _ForgotpassState();
}

class _ForgotpassState extends State<Forgotpass> {
  final TextEditingController _emailPhoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _otpSent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //  AppBar có nút back
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
        backgroundColor: Color.fromRGBO(254, 254, 253, 1.0),
        foregroundColor: Colors.orange,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Quay về màn hình trước
          },
        ),
      ),

      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/img/background6.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Nội dung chính
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),

                // Logo
                Image.asset(
                  'assets/img/logo4.png',
                  width: 200,
                  height: 200,
                ),

                const SizedBox(height: 10),

                // Form nổi
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
                      const Text(
                        "Quên mật khẩu",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Nhập email/số điện thoại
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

                      const SizedBox(height: 20),

                      // Nếu đã gửi OTP thì hiển thị ô nhập OTP
                      if (_otpSent)
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

                      const SizedBox(height: 30),

                      ElevatedButton(
                        onPressed: _otpSent ? _verifyOtp : _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(_otpSent ? 'Xác nhận OTP' : 'Gửi mã OTP'),
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
      _showSnackBar("Xác nhận thành công. Tiếp tục đặt lại mật khẩu.");
      // TODO: Chuyển qua màn hình đặt lại mật khẩu
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}