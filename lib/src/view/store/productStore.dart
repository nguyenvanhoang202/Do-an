import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_application_2/src/view/user/prodStoreScreen.dart';
import '../../model/product.dart';
import '../user/productScreen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? storeId;
  List<Product> products = [];
  List<String> selectedProducts = [];
  bool isLoading = true;
  String? error;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  String _selectedCategory = "cat1";
  String _status = "available";

  final Map<String, String> _categories = {
    "cat1": "Các món cơm",
    "cat2": "Các món phở, bún",
    "cat3": "Các loại đồ uống",
    "cat4": "Các món ăn vặt",
    "cat5": "Các loại chè",
  };

  @override
  void initState() {
    super.initState();
    _loadStoreId();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreId() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          error = "Người dùng chưa đăng nhập.";
          isLoading = false;
        });
        return;
      }

      final userSnapshot = await _database.child('users/${user.uid}/storeId').get();
      if (userSnapshot.exists && userSnapshot.value != null) {
        setState(() {
          storeId = userSnapshot.value.toString();
        });

        _loadProducts();
      } else {
        setState(() {
          error = "Không tìm thấy storeId của người dùng.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Có lỗi xảy ra khi lấy storeId: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    if (storeId == null) return;

    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final productsSnapshot = await _database.child('products').get();
      if (productsSnapshot.exists && productsSnapshot.value != null) {
        final productsData = Map<String, dynamic>.from(productsSnapshot.value as Map);

        final List<Product> loadedProducts = [];
        productsData.forEach((key, value) {
          try {
            if (value is Map) {
              final productData = Map<String, dynamic>.from(value);
              productData['id'] = key;

              if (productData['storeId'] == storeId) {
                final product = Product.fromMap(productData, {}, {});
                loadedProducts.add(product);
              }
            }
          } catch (e) {
            print('Lỗi xử lý sản phẩm $key: $e');
          }
        });

        setState(() {
          products = loadedProducts;
          isLoading = false;
        });
      } else {
        setState(() {
          products = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState() {
        error = 'Có lỗi xảy ra khi tải sản phẩm: $e';
        isLoading = false;
      }
  }
  }

  void _toggleSelection(String productId) {
    setState(() {
      if (selectedProducts.contains(productId)) {
        selectedProducts.remove(productId);
      } else {
        selectedProducts.add(productId);
      }
    });
  }

  Future<void> _deleteSelectedProducts() async {
    try {
      for (String productId in selectedProducts) {
        await _database.child('products/$productId').remove();
      }
      setState(() {
        products.removeWhere((product) => selectedProducts.contains(product.id));
        selectedProducts.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xóa sản phẩm thành công!'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xóa sản phẩm: $e'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _showAddProductDialog() {
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
                          "Thêm sản phẩm mới",
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
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: "Tên sản phẩm",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.fastfood, color: Colors.orange[700]),
                      ),
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: "Giá sản phẩm (VND)",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.attach_money, color: Colors.orange[700]),
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: "Mô tả sản phẩm",
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
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _imageController,
                      decoration: InputDecoration(
                        labelText: "URL hình ảnh",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.image, color: Colors.orange[700]),
                      ),
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: "Danh mục",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.category, color: Colors.orange[700]),
                      ),
                      items: _categories.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _status,
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
                      items: const [
                        DropdownMenuItem(
                          value: "available",
                          child: Text("Có sẵn"),
                        ),
                        DropdownMenuItem(
                          value: "out_of_stock",
                          child: Text("Hết hàng"),
                        ),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          _status = value!;
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
                        onPressed: _addNewProduct,
                        child: Text(
                          "Lưu sản phẩm",
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

  Future<void> _addNewProduct() async {
    if (storeId == null) return;

    try {
      final newProductRef = _database.child('products').push();
      final newProductId = newProductRef.key;

      if (newProductId == null) return;

      await newProductRef.set({
        'categoryId': _selectedCategory,
        'description': _descriptionController.text,
        'image': _imageController.text,
        'name': _nameController.text,
        'price': int.tryParse(_priceController.text) ?? 0,
        'rating': 0,
        'status': _status,
        'storeId': storeId,
      });

      _nameController.clear();
      _priceController.clear();
      _descriptionController.clear();
      _imageController.clear();
      setState(() {
        _status = "available";
        _selectedCategory = "cat1";
      });

      Navigator.pop(context);
      _loadProducts();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thêm sản phẩm thành công!'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi thêm sản phẩm: $e'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
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
          'Danh sách sản phẩm',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
        actions: [
          if (selectedProducts.isEmpty)
            IconButton(
              icon: Icon(Icons.add, color: Colors.orange[700], size: 28),
              onPressed: _showAddProductDialog,
              tooltip: 'Thêm sản phẩm',
            ),
          if (selectedProducts.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.orange[700], size: 28),
              onPressed: _deleteSelectedProducts,
              tooltip: 'Xóa sản phẩm đã chọn',
            ),
        ],
        elevation: 0,
        titleSpacing: 16,
        iconTheme: IconThemeData(color: Colors.orange[700]),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: Colors.orange[700],
        ),
      )
          : error != null
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
              error!,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _loadStoreId,
              child: Text(
                'Thử lại',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final isSelected = selectedProducts.contains(product.id);
          return GestureDetector(
            onTap: () {
              if (selectedProducts.isEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailPageAdmin(
                      productId: product.id,
                    ),
                  ),
                );
              } else {
                _toggleSelection(product.id);
              }
            },
            onLongPress: () => _toggleSelection(product.id),
            child: Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              color: isSelected ? Colors.grey[300] : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: product.image != null && product.image!.isNotEmpty
                          ? Image.network(
                        product.image!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.broken_image,
                              size: 40,
                              color: Colors.orange[700],
                            ),
                          );
                        },
                      )
                          : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.fastfood,
                          size: 40,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${product.price.toStringAsFixed(0)}₫',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}