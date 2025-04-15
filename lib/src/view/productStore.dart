import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_application_2/src/view/prodScreen.dart';
import '../model/product.dart';
import 'productScreen.dart';

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
      setState(() {
        error = 'Có lỗi xảy ra khi tải sản phẩm: $e';
        isLoading = false;
      });
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
    } catch (e) {
      print('Lỗi khi xóa sản phẩm: $e');
    }
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thêm sản phẩm mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên sản phẩm',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Giá sản phẩm (VND)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả sản phẩm',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _imageController,
                  decoration: const InputDecoration(
                    labelText: 'URL hình ảnh',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Danh mục',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái',
                    border: OutlineInputBorder(),
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
                    if (value != null) {
                      setState(() {
                        _status = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: _addNewProduct,
              child: const Text('Thêm'),
            ),
          ],
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
        const SnackBar(
          content: Text('Thêm sản phẩm thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi thêm sản phẩm: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách sản phẩm'),
        actions: [
          if (selectedProducts.isEmpty)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddProductDialog,
              tooltip: 'Thêm sản phẩm',
            ),
          if (selectedProducts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelectedProducts,
              tooltip: 'Xóa sản phẩm đã chọn',
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _loadStoreId,
              child: const Text('Thử lại'),
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
              color: isSelected ? Colors.grey[300] : null,
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
                            child: const Icon(Icons.broken_image, size: 40, color: Colors.orange),
                          );
                        },
                      )
                          : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.fastfood, size: 40, color: Colors.orange),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${product.price.toStringAsFixed(0)}₫',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: Colors.green),
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