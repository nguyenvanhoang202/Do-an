import 'package:flutter/material.dart';
import '../../blocs/auth_bloc.dart';
import 'Login_view.dart';

class Register extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<Register> {
  final AuthBloc authBloc = AuthBloc();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passError;
  String? _confirmPassError;

  bool _isLoading = false;

  @override
  void dispose() {
    authBloc.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  //Xử lý đăng ký, kiểm tra dữ liệu nhập, gọi AuthBloc để đăng ký và điều hướng.
  void _register() {
    setState(() {
      _nameError = _emailError = _phoneError = _passError = _confirmPassError = null;

      if (_nameController.text.isEmpty || _nameController.text.length < 2) {
        _nameError = 'Họ tên phải có ít nhất 2 ký tự';
      }

      if (!_emailController.text.contains('@')) {
        _emailError = 'Email không hợp lệ';
      }

      if (!RegExp(r'^[0-9]{10}$').hasMatch(_phoneController.text)) {
        _phoneError = 'Số điện thoại không hợp lệ';
      }

      if (_passController.text.length < 8 ||
          !_passController.text.contains(RegExp(r'[A-Z]')) ||
          !_passController.text.contains(RegExp(r'[a-z]')) ||
          !_passController.text.contains(RegExp(r'[0-9]'))) {
        _passError = 'Mật khẩu phải từ 8 ký tự, có chữ hoa, thường và số';
      }

      if (_passController.text != _confirmPasswordController.text) {
        _confirmPassError = 'Mật khẩu xác nhận không khớp';
      }
    });

    if (_nameError == null &&
        _emailError == null &&
        _phoneError == null &&
        _passError == null &&
        _confirmPassError == null) {
      setState(() => _isLoading = true);
      authBloc.signUp(
        _emailController.text,
        _passController.text,
        _phoneController.text,
        _nameController.text,
            (isSuccess, error) {
          setState(() => _isLoading = false);
          if (isSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Login()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error ?? 'Đăng ký thất bại'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    }
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    String? errorText,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: Colors.orange),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.orange, width: 2),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(errorText, style: const TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                const SizedBox(height: 10),
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
                      const Text(
                        "Đăng ký",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildInput(
                        controller: _nameController,
                        label: 'Họ tên',
                        icon: Icons.person,
                        errorText: _nameError,
                      ),
                      const SizedBox(height: 16),
                      _buildInput(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                      ),
                      const SizedBox(height: 16),
                      _buildInput(
                        controller: _phoneController,
                        label: 'Số điện thoại',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        errorText: _phoneError,
                      ),
                      const SizedBox(height: 16),
                      _buildInput(
                        controller: _passController,
                        label: 'Mật khẩu',
                        icon: Icons.lock,
                        obscure: true,
                        errorText: _passError,
                      ),
                      const SizedBox(height: 16),
                      _buildInput(
                        controller: _confirmPasswordController,
                        label: 'Xác nhận mật khẩu',
                        icon: Icons.lock_outline,
                        obscure: true,
                        errorText: _confirmPassError,
                      ),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 60,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "Đăng ký",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => Login()),
                          );
                        },
                        child: const Text(
                          "Đã có tài khoản? Đăng nhập",
                          style: TextStyle(color: Colors.orange),
                        ),
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
}