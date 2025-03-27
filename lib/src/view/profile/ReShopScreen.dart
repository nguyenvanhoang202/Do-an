import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../account/Login_view.dart';
import 'package:flutter/services.dart';

class RegisterShopScreen extends StatefulWidget {
  @override
  _RegisterShopScreenState createState() => _RegisterShopScreenState();
}

class _RegisterShopScreenState extends State<RegisterShopScreen> {
  final FirebaseAuth _fireBaseAuth = FirebaseAuth.instance;
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();

  bool _agreeTerms = false;
  bool _hasStore = false;
  final TextEditingController _storeIdController = TextEditingController();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _storePhoneController = TextEditingController();
  final TextEditingController _storeAddressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đăng ký cửa hàng',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Đăng ký tài khoản cửa hàng",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Chọn đã có hoặc chưa có cửa hàng
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text("Đã có cửa hàng"),
                    value: true,
                    groupValue: _hasStore,
                    activeColor: Colors.orange,
                    onChanged: (value) => setState(() => _hasStore = value!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text("Chưa có cửa hàng"),
                    value: false,
                    groupValue: _hasStore,
                    activeColor: Colors.orange,
                    onChanged: (value) => setState(() => _hasStore = value!),
                  ),
                ),
              ],
            ),

            if (_hasStore) _buildExistingStoreInput() else _buildNewStoreForm(),

            const SizedBox(height: 16),
            const Divider(),

            // Điều khoản
            const Text(
              "Quy định và điều khoản của cửa hàng",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "• Tuân thủ quy định của hệ thống.\n"
                  "• Không bán hàng cấm hoặc vi phạm pháp luật.\n"
                  "• Cung cấp thông tin chính xác.\n"
                  "• Tuân thủ chính sách hoàn trả và bảo hành.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Checkbox(
                  value: _agreeTerms,
                  activeColor: Colors.orange,
                  onChanged: (bool? value) {
                    setState(() {
                      _agreeTerms = value!;
                    });
                  },
                ),
                const Expanded(
                  child: Text(
                    "Tôi đồng ý với điều khoản trên",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _agreeTerms ? () => _confirmRegisterShop(context) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _agreeTerms ? Colors.orange : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Center(
                child: Text(
                  "Đăng ký ngay",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Form nhập storeId nếu đã có cửa hàng
  Widget _buildExistingStoreInput() {
    return Column(
      children: [
        TextField(
          controller: _storeIdController,
          decoration: const InputDecoration(labelText: "Nhập Store ID của cửa hàng"),
        ),
      ],
    );
  }

  /// Form tạo cửa hàng nếu chưa có
  Widget _buildNewStoreForm() {
    return Column(
      children: [
        TextField(
          controller: _storeNameController,
          decoration: const InputDecoration(labelText: "Tên cửa hàng"),
        ),
        TextField(
          controller: _storePhoneController,
          decoration: const InputDecoration(labelText: "Số điện thoại"),
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Chỉ cho phép nhập số
        ),
        TextField(
          controller: _storeAddressController,
          decoration: const InputDecoration(labelText: "Địa chỉ"),
        ),
      ],
    );
  }

  /// Xác nhận đăng ký
  void _confirmRegisterShop(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Xác nhận đăng ký"),
          content: const Text("Bạn có chắc chắn muốn đăng ký cửa hàng không?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _hasStore ? _registerExistingStore() : _registerNewStore();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text("Đồng ý"),
            ),
          ],
        );
      },
    );
  }

  /// Đăng ký cửa hàng mới
  Future<void> _registerNewStore() async {
    try {
      User? currentUser = _fireBaseAuth.currentUser;
      if (currentUser == null) throw Exception("Người dùng chưa đăng nhập!");

      String storeId = _databaseReference.child("stores").push().key!;
      await _databaseReference.child("stores/$storeId").set({
        "id": storeId,
        "name": _storeNameController.text,
        "phoneNumber": _storePhoneController.text,
        "address": _storeAddressController.text,
        "status": "open",
        "rating": 0.0,
        "image": null,
      });

      await _databaseReference.child("users/${currentUser.uid}").update({
        "storeId": storeId,
        "position": 2,
      });

      _showSuccessDialog();
    } catch (error) {
      _showError(error);
    }
  }

  /// Liên kết tài khoản với cửa hàng đã có
  Future<void> _registerExistingStore() async {
    try {
      User? currentUser = _fireBaseAuth.currentUser;
      if (currentUser == null) throw Exception("Người dùng chưa đăng nhập!");

      String storeId = _storeIdController.text.trim();
      if (storeId.isEmpty) throw Exception("Vui lòng nhập Store ID!");

      await _databaseReference.child("users/${currentUser.uid}").update({
        "storeId": storeId,
        "position": 2,
      });

      _showSuccessDialog();
    } catch (error) {
      _showError(error);
    }
  }

  /// Hiển thị thông báo thành công
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Đăng ký thành công"),
          content: const Text("Bạn đã đăng ký cửa hàng thành công!"),
          actions: [
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _fireBaseAuth.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => Login()),
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  /// Hiển thị lỗi
  void _showError(error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $error")));
  }
}