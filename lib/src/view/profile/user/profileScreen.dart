import 'dart:convert';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../firebase/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../../account/Login_view.dart';
import 'package:intl/intl.dart';
import '../../../model/feedback.dart' as FeedbackModel;
import '../store/ReShopScreen.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirAuth _auth = FirAuth();
  Map<String, dynamic>? _userDetails;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _updateAvatar() async {
    try {
      await showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        backgroundColor: Colors.white,
        builder: (BuildContext context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.photo_library, color: Colors.grey[600]),
                    title: Text(
                      'Chọn từ thư viện',
                      style: TextStyle(fontSize: 16, color: Colors.grey[900]),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndUploadImage(ImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.camera_alt, color: Colors.grey[600]),
                    title: Text(
                      'Chụp ảnh mới',
                      style: TextStyle(fontSize: 16, color: Colors.grey[900]),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickAndUploadImage(ImageSource.camera);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      _showErrorMessage('Không thể mở trình chọn ảnh');
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      setState(() => _isUploadingImage = true);

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (pickedFile == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      final File imageFile = File(pickedFile.path);
      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      final int sizeInBytes = base64Image.length;
      final double sizeInMB = sizeInBytes / (1024 * 1024);

      if (sizeInMB > 1) {
        setState(() => _isUploadingImage = false);
        _showErrorMessage('Ảnh quá lớn. Vui lòng chọn ảnh nhỏ hơn');
        return;
      }

      final User? currentUser = _auth.getCurrentUser();
      if (currentUser == null) throw Exception("Người dùng chưa đăng nhập");

      await _auth.updateUserDetail(
          currentUser.uid, {'image': 'data:image/jpeg;base64,$base64Image'});

      await _loadUserData();

      setState(() => _isUploadingImage = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cập nhật ảnh đại diện thành công'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (error) {
      setState(() => _isUploadingImage = false);
      _showErrorMessage('Lỗi khi cập nhật ảnh: ${error.toString()}');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
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
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(currentUser.uid)
          .get();

      if (snapshot.exists) {
        setState(() {
          _userDetails = userDetails;
          _userData = Map<String, dynamic>.from(snapshot.value as Map);
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() => _isLoading = false);
      _showErrorMessage('Lỗi khi tải thông tin: ${error.toString()}');
    }
  }

  Future<void> _updateUserDetail(String field, dynamic value) async {
    try {
      final User? currentUser = _auth.getCurrentUser();
      if (currentUser == null) return;

      await _auth.updateUserDetail(currentUser.uid, {field: value});

      await _loadUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cập nhật thành công'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (error) {
      _showErrorMessage('Lỗi khi cập nhật: ${error.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.orange[700],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.8),
                Colors.white.withOpacity(0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Thông tin cá nhân',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
        iconTheme: IconThemeData(color: Colors.orange[700]),
        actions: [
          IconButton(
            icon: Icon(Icons.add_business, color: Colors.orange[700]),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegisterShopScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
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
                          child: _buildAvatar(),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _updateAvatar,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 20,
                              color: Colors.orange[800],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userData?['name'] ?? 'Chưa cập nhật tên',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _userData?['email'] ?? 'Chưa có email',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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
                    'Danh sách đánh giá',
                    Icons.star_outline_rounded,
                    _showReviewsList,
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
    try {
      if (_userDetails != null &&
          _userDetails!['image'] != null &&
          _userDetails!['image'].toString().startsWith('data:image')) {
        final imageData = _userDetails!['image'].toString().split(',');
        if (imageData.length > 1) {
          return Image.memory(
            base64Decode(imageData[1]),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
          );
        }
      }
      return _buildDefaultAvatar();
    } catch (e) {
      return _buildDefaultAvatar();
    }
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey[200],
      child: Icon(
        Icons.person_rounded,
        size: 60,
        color: Colors.grey[400],
      ),
    );
  }

  Future<bool?> _showLogoutConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Đăng xuất',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất?',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Đăng xuất',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
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
                      fontWeight: FontWeight.w500,
                      color: textColor ?? Colors.grey[900],
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
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Future<void> _showEditProfileDialog() async {
    final TextEditingController nameController = TextEditingController(text: _userData?['name']);
    final TextEditingController phoneController = TextEditingController(text: _userData?['phone']);
    final TextEditingController addressController = TextEditingController(text: _userDetails?['diachi']);
    String? selectedGender = _userDetails?['gioitinh'];
    String? selectedDate = _userDetails?['date'];
    bool isLoading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Chỉnh sửa thông tin",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.grey[600]),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Họ và tên",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.person, color: Colors.orange[700]),
                      ),
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: "Số điện thoại",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.phone, color: Colors.orange[700]),
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedGender,
                      decoration: InputDecoration(
                        labelText: "Giới tính",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.person_outline, color: Colors.orange[700]),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                        DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                        DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                      ],
                      onChanged: (value) {
                        setModalState(() => selectedGender = value);
                      },
                    ),
                    const SizedBox(height: 16),
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
                          setModalState(() {
                            selectedDate = picked.toIso8601String().split('T')[0];
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Ngày sinh",
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.calendar_today, color: Colors.orange[700]),
                        ),
                        child: Text(
                          selectedDate ?? 'Chọn ngày sinh',
                          style: TextStyle(
                            fontSize: 16,
                            color: selectedDate != null ? Colors.grey[900] : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: "Địa chỉ",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.location_on, color: Colors.orange[700]),
                      ),
                      maxLines: 2,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: isLoading
                            ? null
                            : () async {
                          setModalState(() => isLoading = true);
                          try {
                            final User? currentUser = _auth.getCurrentUser();
                            if (currentUser != null) {
                              await FirebaseDatabase.instance
                                  .ref()
                                  .child('users')
                                  .child(currentUser.uid)
                                  .update({
                                'name': nameController.text,
                                'phone': phoneController.text,
                              });

                              await _auth.updateUserDetail(currentUser.uid, {
                                'gioitinh': selectedGender,
                                'date': selectedDate,
                                'diachi': addressController.text,
                              });

                              await _loadUserData();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Cập nhật thông tin thành công'),
                                  backgroundColor: Colors.green[600],
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            _showErrorMessage('Lỗi khi cập nhật thông tin');
                          } finally {
                            setModalState(() => isLoading = false);
                          }
                        },
                        child: isLoading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : const Text(
                          "Lưu",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final TextEditingController currentPassController = TextEditingController();
    final TextEditingController newPassController = TextEditingController();
    final TextEditingController confirmPassController = TextEditingController();
    bool isLoading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Đổi mật khẩu",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.grey[600]),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: currentPassController,
                      decoration: InputDecoration(
                        labelText: "Mật khẩu hiện tại",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.lock, color: Colors.orange[700]),
                      ),
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPassController,
                      decoration: InputDecoration(
                        labelText: "Mật khẩu mới",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.lock, color: Colors.orange[700]),
                      ),
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPassController,
                      decoration: InputDecoration(
                        labelText: "Xác nhận mật khẩu mới",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.lock, color: Colors.orange[700]),
                      ),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: isLoading
                            ? null
                            : () async {
                          if (newPassController.text != confirmPassController.text) {
                            _showErrorMessage('Mật khẩu mới không khớp');
                            return;
                          }

                          setModalState(() => isLoading = true);

                          try {
                            final user = _auth.getCurrentUser();
                            if (user != null) {
                              final credential = EmailAuthProvider.credential(
                                email: user.email!,
                                password: currentPassController.text,
                              );
                              await user.reauthenticateWithCredential(credential);

                              await user.updatePassword(newPassController.text);

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Đổi mật khẩu thành công'),
                                  backgroundColor: Colors.green[600],
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            _showErrorMessage('Mật khẩu hiện tại không đúng');
                          } finally {
                            setModalState(() => isLoading = false);
                          }
                        },
                        child: isLoading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : const Text(
                          "Xác nhận",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showReviewsList() async {
    try {
      final User? currentUser = _auth.getCurrentUser();
      if (currentUser == null) return;

      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('feedbacks')
          .orderByChild('userId')
          .equalTo(currentUser.uid)
          .get();

      if (!snapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Chưa có đánh giá nào'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }

      final feedbacksMap = Map<String, dynamic>.from(snapshot.value as Map);
      List<FeedbackModel.Feedback> feedbacks = [];

      for (var entry in feedbacksMap.entries) {
        final feedbackData = Map<String, dynamic>.from(entry.value);
        feedbackData['id'] = entry.key;

        Map<String, dynamic> userData = {
          'id': feedbackData['userId'],
          'name': 'Người dùng ẩn danh',
          'email': '',
          'phone': '',
        };

        if (feedbackData['userId'] != null) {
          final userSnapshot = await FirebaseDatabase.instance
              .ref()
              .child('users')
              .child(feedbackData['userId'])
              .get();

          if (userSnapshot.exists) {
            userData = Map<String, dynamic>.from(userSnapshot.value as Map);
            userData['id'] = feedbackData['userId'];
          }
        }

        final productSnapshot = await FirebaseDatabase.instance
            .ref()
            .child('products')
            .child(feedbackData['productId'])
            .get();

        if (productSnapshot.exists) {
          final productData = Map<String, dynamic>.from(productSnapshot.value as Map);
          productData['id'] = feedbackData['productId'];

          feedbacks.add(FeedbackModel.Feedback.fromMap(feedbackData, userData, productData));
        }
      }

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Danh sách đánh giá',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          content: SizedBox(
            height: 400,
            width: 300,
            child: ListView.builder(
              itemCount: feedbacks.length,
              itemBuilder: (context, index) {
                final feedback = feedbacks[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feedback.user.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < feedback.rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feedback.content,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                        if (feedback.image != null) ...[
                          const SizedBox(height: 8),
                          Image.memory(
                            base64Decode(feedback.image!.split(',').last),
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(
                            DateTime.fromMillisecondsSinceEpoch(feedback.createdAt),
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Đóng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      );
    } catch (error) {
      _showErrorMessage('Lỗi khi tải danh sách đánh giá: ${error.toString()}');
    }
  }
}