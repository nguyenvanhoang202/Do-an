import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../account/Login_view.dart';
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
  bool _isLoading = false;
  final TextEditingController _storeIdController = TextEditingController();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _storePhoneController = TextEditingController();
  final TextEditingController _storeAddressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.orange[700]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Đăng ký cửa hàng',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đăng ký tài khoản cửa hàng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 24),
            Container(
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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: Text(
                            'Đã có cửa hàng',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[900],
                            ),
                          ),
                          value: true,
                          groupValue: _hasStore,
                          activeColor: Colors.orange[700],
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tileColor: _hasStore ? Colors.grey[100] : null,
                          onChanged: (value) => setState(() => _hasStore = value!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: Text(
                            'Chưa có cửa hàng',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[900],
                            ),
                          ),
                          value: false,
                          groupValue: _hasStore,
                          activeColor: Colors.orange[700],
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tileColor: !_hasStore ? Colors.grey[100] : null,
                          onChanged: (value) => setState(() => _hasStore = value!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_hasStore) _buildExistingStoreInput() else _buildNewStoreForm(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quy định và điều khoản của cửa hàng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Tuân thủ quy định của hệ thống.\n'
                        '• Không bán hàng cấm hoặc vi phạm pháp luật.\n'
                        '• Cung cấp thông tin chính xác.\n'
                        '• Tuân thủ chính sách hoàn trả và bảo hành.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically centered
                    children: [
                      Checkbox(
                        value: _agreeTerms,
                        activeColor: Colors.orange[700],
                        onChanged: (bool? value) {
                          setState(() => _agreeTerms = value!);
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduce padding
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2.0), // Fine-tune vertical alignment if needed
                          child: Text.rich(
                            TextSpan(
                              text: 'Tôi đồng ý với ',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[900],
                              ),
                              children: [
                                TextSpan(
                                  text: 'điều khoản trên',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _agreeTerms && !_isLoading ? Colors.orange[700] : Colors.grey[400],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: _agreeTerms && !_isLoading ? () => _confirmRegisterShop(context) : null,
                child: _isLoading
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : const Text(
                  'Đăng ký ngay',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingStoreInput() {
    return TextField(
      controller: _storeIdController,
      decoration: InputDecoration(
        labelText: 'Store ID',
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(Icons.store, color: Colors.orange[700]),
        labelStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey[700],
        ),
      ),
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
    );
  }

  Widget _buildNewStoreForm() {
    return Column(
      children: [
        TextField(
          controller: _storeNameController,
          decoration: InputDecoration(
            labelText: 'Tên cửa hàng',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.store, color: Colors.orange[700]),
            labelStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _storePhoneController,
          decoration: InputDecoration(
            labelText: 'Số điện thoại',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.phone, color: Colors.orange[700]),
            labelStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _storeAddressController,
          decoration: InputDecoration(
            labelText: 'Địa chỉ',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.location_on, color: Colors.orange[700]),
            labelStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          keyboardType: TextInputType.streetAddress,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  void _confirmRegisterShop(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Xác nhận đăng ký',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn đăng ký cửa hàng không?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Hủy',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _hasStore ? _registerExistingStore() : _registerNewStore();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Đồng ý',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _registerNewStore() async {
    if (_storeNameController.text.trim().isEmpty) {
      _showError('Vui lòng nhập tên cửa hàng');
      return;
    }
    if (_storePhoneController.text.trim().isEmpty || _storePhoneController.text.length < 10) {
      _showError('Vui lòng nhập số điện thoại hợp lệ');
      return;
    }
    if (_storeAddressController.text.trim().isEmpty) {
      _showError('Vui lòng nhập địa chỉ');
      return;
    }

    setState(() => _isLoading = true);
    try {
      User? currentUser = _fireBaseAuth.currentUser;
      if (currentUser == null) throw Exception('Người dùng chưa đăng nhập!');

      String storeId = _databaseReference.child('stores').push().key!;
      await _databaseReference.child('stores/$storeId').set({
        'id': storeId,
        'name': _storeNameController.text.trim(),
        'phoneNumber': _storePhoneController.text.trim(),
        'address': _storeAddressController.text.trim(),
        'status': 'open',
        'rating': 0.0,
        'image': null,
      });

      await _databaseReference.child('users/${currentUser.uid}').update({
        'storeId': storeId,
        'position': 2,
      });

      setState(() => _isLoading = false);
      _showSuccessDialog();
    } catch (error) {
      setState(() => _isLoading = false);
      _showError(error.toString());
    }
  }

  Future<void> _registerExistingStore() async {
    if (_storeIdController.text.trim().isEmpty) {
      _showError('Vui lòng nhập Store ID');
      return;
    }

    setState(() => _isLoading = true);
    try {
      User? currentUser = _fireBaseAuth.currentUser;
      if (currentUser == null) throw Exception('Người dùng chưa đăng nhập!');

      String storeId = _storeIdController.text.trim();
      DatabaseEvent storeSnapshot = await _databaseReference.child('stores/$storeId').once();
      if (!storeSnapshot.snapshot.exists) {
        throw Exception('Store ID không tồn tại');
      }

      await _databaseReference.child('users/${currentUser.uid}').update({
        'storeId': storeId,
        'position': 2,
      });

      setState(() => _isLoading = false);
      _showSuccessDialog();
    } catch (error) {
      setState(() => _isLoading = false);
      _showError(error.toString());
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Đăng ký thành công',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          content: Text(
            'Bạn đã đăng ký cửa hàng thành công!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          actions: [
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await _fireBaseAuth.signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => Login()),
                        (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
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
}