import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../model/store.dart';
import 'package:flutter/services.dart';

class StoreInfoScreen extends StatefulWidget {
  @override
  _StoreInfoScreenState createState() => _StoreInfoScreenState();
}

class _StoreInfoScreenState extends State<StoreInfoScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Store? store;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  Future<void> _loadStore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          errorMessage = "Bạn chưa đăng nhập";
          isLoading = false;
        });
        return;
      }

      final userSnapshot = await _database.child('users').child(user.uid).get();
      if (!userSnapshot.exists) {
        setState(() {
          errorMessage = "Không tìm thấy thông tin người dùng";
          isLoading = false;
        });
        return;
      }

      final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
      String? storeId = userData['storeId'];

      if (storeId == null) {
        setState(() {
          errorMessage = "Bạn không có cửa hàng để quản lý";
          isLoading = false;
        });
        return;
      }

      final storeSnapshot = await _database.child('stores').child(storeId).get();
      if (!storeSnapshot.exists) {
        setState(() {
          errorMessage = "Không tìm thấy cửa hàng của bạn";
          isLoading = false;
        });
        return;
      }

      final storeData = Map<String, dynamic>.from(storeSnapshot.value as Map);
      setState(() {
        store = Store(
          id: storeId,
          name: storeData['name'] ?? "Không có tên",
          description: storeData['description'] ?? "",
          phoneNumber: storeData['phoneNumber'] ?? "",
          address: storeData['address'] ?? "",
          status: storeData['status'] ?? "open",
          rating: (storeData['rating'] as num?)?.toDouble() ?? 0.0,
          image: storeData['image'] ?? "",
        );
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Lỗi khi tải dữ liệu: $e";
        isLoading = false;
      });
    }
  }

  void _showEditForm() {
    if (store == null) return;

    TextEditingController nameController = TextEditingController(text: store!.name);
    TextEditingController addressController = TextEditingController(text: store!.address);
    TextEditingController phoneController = TextEditingController(text: store!.phoneNumber);
    TextEditingController descriptionController = TextEditingController(text: store!.description);
    TextEditingController imageController = TextEditingController(text: store!.image ?? "");
    String status = store!.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
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
                  "Sửa thông tin cửa hàng",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Tên cửa hàng",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9À-ỹ ]')),
              ],

            ),
            SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: "Địa chỉ",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9À-ỹ ]')),
              ],
            ),
            SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: "Số điện thoại",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: "Mô tả",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9À-ỹ ]')),
              ],
            ),
            SizedBox(height: 12),
            TextField(
              controller: imageController,
              decoration: InputDecoration(
                labelText: "URL Ảnh cửa hàng",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: status,
              decoration: InputDecoration(
                labelText: "Trạng thái",
                border: OutlineInputBorder(),
              ),
              items: ["open", "close"].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  status = newValue!;
                });
              },
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {  // Đây là nơi đúng để đặt onPressed
                  try {
                    await _database.child('stores').child(store!.id).update({
                      "name": nameController.text,
                      "address": addressController.text,
                      "phoneNumber": phoneController.text,
                      "description": descriptionController.text,
                      "image": imageController.text,
                      "status": status,
                    });

                    setState(() {
                      store = Store(
                        id: store!.id,
                        name: nameController.text,
                        address: addressController.text,
                        phoneNumber: phoneController.text,
                        description: descriptionController.text,
                        image: imageController.text,
                        status: status,
                        rating: store!.rating,
                      );
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Cập nhật thông tin thành công!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    print("Lỗi cập nhật: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Lỗi khi cập nhật thông tin!"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text(
                  "Lưu thay đổi",
                  style: TextStyle(fontSize: 16),
                ),
                ),
              ),
              SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
        child: Text(
          errorMessage!,
          style: TextStyle(fontSize: 18, color: Colors.red),
        ),
      )
          : CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: store != null && store!.image != null && store!.image!.isNotEmpty
                  ? Image.network(
                store!.image!,
                fit: BoxFit.cover,
              )
                  : Container(
                color: Colors.grey[200],
                child: Center(
                  child: Icon(
                    Icons.store,
                    size: 80,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store!.name,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto'),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(store!.address,
                            style: TextStyle(
                                fontSize: 18, fontFamily: 'Roboto')),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Text(store!.phoneNumber,
                          style: TextStyle(
                              fontSize: 18, fontFamily: 'Roboto')),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.orange[800]),
                      SizedBox(width: 8),
                      Text(
                        store!.rating.toStringAsFixed(1),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto'),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Trạng thái: ${store!.status}",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto'),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Mô tả cửa hàng:",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto'),
                  ),
                  SizedBox(height: 5),
                  Text(
                    store!.description,
                    style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Roboto',
                        height: 1.5,
                        color: Colors.grey[700]),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: errorMessage == null && !isLoading
          ? FloatingActionButton.extended(
        onPressed: _showEditForm,
        icon: Icon(Icons.edit, color: Colors.black),
        label: Text("Sửa thông tin",style: TextStyle( color: Colors.black),),
        backgroundColor: Colors.orange[800],
        elevation: 4,
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}