import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../model/store.dart';
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
      shape: RoundedRectangleBorder(
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
                    SizedBox(height: 24),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Tên cửa hàng",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.store, color: Colors.orange[700]),
                      ),
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9À-ỹ ]')),
                      ],
                    ),
                    SizedBox(height: 16),
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
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9À-ỹ ]')),
                      ],
                    ),
                    SizedBox(height: 16),
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
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: "Mô tả",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.description, color: Colors.orange[700]),
                      ),
                      maxLines: 3,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9À-ỹ ]')),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: imageController,
                      decoration: InputDecoration(
                        labelText: "URL Ảnh cửa hàng",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.image, color: Colors.orange[700]),
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: InputDecoration(
                        labelText: "Trạng thái",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.toggle_on, color: Colors.orange[700]),
                      ),
                      items: ["open", "close"].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value.capitalize()),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setModalState(() {
                          status = newValue!;
                        });
                      },
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () async {
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
                                backgroundColor: Colors.green[600],
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          } catch (e) {
                            print("Lỗi cập nhật: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Lỗi khi cập nhật thông tin!"),
                                backgroundColor: Colors.red[600],
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          }
                        },
                        child: Text(
                          "Lưu thay đổi",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.8),
                Colors.white.withOpacity(0.2),
              ],
            ),
          ),
        ),
        title: Text(
          "Thông tin cửa hàng",
          style: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: errorMessage == null && !isLoading
            ? [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.orange[700]),
            onPressed: _showEditForm,
            tooltip: "Chỉnh sửa",
          ),
        ]
            : null,
        elevation: 0,
        titleSpacing: 16,
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: Colors.orange[700],
        ),
      )
          : errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red[600],
            ),
            SizedBox(height: 16),
            Text(
              errorMessage!,
              style: TextStyle(
                fontSize: 20,
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.orange[700],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  store != null && store!.image != null && store!.image!.isNotEmpty
                      ? Image.network(
                    store!.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.store,
                        size: 80,
                        color: Colors.orange[700],
                      ),
                    ),
                  )
                      : Container(
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.store,
                      size: 80,
                      color: Colors.orange[700],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                store!.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              titlePadding: EdgeInsets.only(left: 16, bottom: 16),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Thông tin cửa hàng",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.orange[700],
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              store!.address,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.phone,
                            color: Colors.orange[700],
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            store!.phoneNumber,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.orange[700],
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            store!.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Chip(
                        label: Text(
                          store!.status.capitalize(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        backgroundColor: store!.status == 'open'
                            ? Colors.green[600]
                            : Colors.red[600],
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        "Mô tả cửa hàng",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        store!.description.isEmpty
                            ? "Chưa có mô tả"
                            : store!.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}