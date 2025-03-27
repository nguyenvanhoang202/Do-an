import 'dart:convert';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../firebase/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../account/Login_view.dart';
import 'package:intl/intl.dart';

class StoreProfileScreen extends StatefulWidget {
  @override
  _StoreProfileScreenState createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  final FirAuth _auth = FirAuth();
  Map<String, dynamic>? _userDetails;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);
      final User? currentUser = _auth.getCurrentUser();
      if (currentUser == null) {
        throw Exception("Không tìm thấy người dùng");
      }
      final userDetails = await _auth.getUserDetail(currentUser.uid);
      final snapshot = await FirebaseDatabase.instance.ref().child('users').child(currentUser.uid).get();
      if (snapshot.exists) {
        setState(() {
          _userDetails = userDetails;
          _userData = Map<String, dynamic>.from(snapshot.value as Map);
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải thông tin: ${error.toString()}')),
      );
    }
  }
  Future<void> _showEditProfileDialog() async {
    final TextEditingController nameController =
    TextEditingController(text: _userData?['name']);
    final TextEditingController phoneController =
    TextEditingController(text: _userData?['phone']);
    final TextEditingController addressController =
    TextEditingController(text: _userDetails?['diachi']);
    String? selectedGender = _userDetails?['gioitinh'];
    String? selectedDate = _userDetails?['date'];
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Chỉnh sửa thông tin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Họ tên
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Số điện thoại
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // Giới tính
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Giới tính',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                    DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                    DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                  ],
                  onChanged: (value) {
                    setState(() => selectedGender = value);
                  },
                ),
                const SizedBox(height: 16),

                // Ngày sinh
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate != null
                          ? DateTime.parse(selectedDate!)
                          : DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked.toIso8601String().split('T')[0];
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Ngày sinh',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      selectedDate ?? 'Chọn ngày sinh',
                      style: TextStyle(
                        color:
                        selectedDate != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Địa chỉ
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            if (isLoading)
              const CircularProgressIndicator()
            else
              TextButton(
                onPressed: () async {
                  setState(() => isLoading = true);
                  try {
                    final User? currentUser = _auth.getCurrentUser();
                    if (currentUser != null) {
                      // Cập nhật thông tin user
                      await FirebaseDatabase.instance
                          .ref()
                          .child('users')
                          .child(currentUser.uid)
                          .update({
                        'name': nameController.text,
                        'phone': phoneController.text,
                      });

                      // Cập nhật thông tin chi tiết
                      await _auth.updateUserDetail(currentUser.uid, {
                        'gioitinh': selectedGender,
                        'date': selectedDate,
                        'diachi': addressController.text,
                      });

                      await _loadUserData();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                            content: Text('Cập nhật thông tin thành công')),
                      );
                    }
                  } catch (e) {
                    _showErrorMessage('Lỗi khi cập nhật thông tin');
                  } finally {
                    setState(() => isLoading = false);
                  }
                },
                child: const Text('Lưu'),
              ),
          ],
        ),
      ),
    );
  }
  Future<void> _showChangePasswordDialog() async {
    final TextEditingController currentPassController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();
    final TextEditingController confirmPassController = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Đổi mật khẩu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPassController,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu hiện tại',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPassController,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu mới',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPassController,
                  decoration: const InputDecoration(
                    labelText: 'Xác nhận mật khẩu mới',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            if (isLoading)
              const CircularProgressIndicator()
            else
              TextButton(
                onPressed: () async {
                  if (newPassController.text != confirmPassController.text) {
                    _showErrorMessage('Mật khẩu mới không khớp');
                    return;
                  }

                  setState(() => isLoading = true);

                  try {
                    final user = _auth.getCurrentUser();
                    if (user != null) {
                      // Xác thực lại người dùng với mật khẩu hiện tại
                      final credential = EmailAuthProvider.credential(
                        email: user.email!,
                        password: currentPassController.text,
                      );
                      await user.reauthenticateWithCredential(credential);

                      // Đổi mật khẩu
                      await user.updatePassword(newPassController.text);

                      Navigator.pop(context);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                            content: Text('Đổi mật khẩu thành công')),
                      );
                    }
                  } catch (e) {
                    _showErrorMessage('Mật khẩu hiện tại không đúng');
                  } finally {
                    setState(() => isLoading = false);
                  }
                },
                child: const Text('Xác nhận'),
              ),
          ],
        ),
      ),
    );
  }
  Future<bool?> _showLogoutConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _handleLogout() async {
    await _auth.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => Login()),
          (route) => false,
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.orange,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Thông tin cửa hàng',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildAvatar(),
                  const SizedBox(height: 16),
                  Text(
                    _userData?['name'] ?? 'Chưa cập nhật tên',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _userData?['email'] ?? 'Chưa có email',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildOptionItem(
                    'Thông tin cá nhân',
                    Icons.person_outline_rounded,
                    _showEditProfileDialog,
                  ),
                  _buildOptionItem(
                    'Đổi mật khẩu',
                    Icons.lock_outline_rounded,
                    _showChangePasswordDialog,
                  ),
                  _buildOptionItem(
                    'Đăng xuất',
                    Icons.logout_rounded,
                        () async {
                      final confirmed = await _showLogoutConfirmDialog();
                      if (confirmed == true) {
                        await _handleLogout();
                      }
                    },
                    textColor: Colors.red[700],
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
      ),
      child: ClipOval(
        child: Container(
          color: Colors.grey[200],
          child: Icon(
            Icons.store_mall_directory,
            size: 60,
            color: Colors.orange,
          ),
        ),
      ),
    );
  }

  Widget _buildOptionItem(
      String title,
      IconData icon,
      VoidCallback onTap, {
        Color? textColor,
        bool showDivider = true,
      }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: textColor ?? Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor ?? Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (showDivider) Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
