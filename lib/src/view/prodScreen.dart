import 'package:flutter/material.dart';
import 'package:flutter_application_2/src/view/productScreen.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import '../model/feedback.dart' as FeedbackModel;
import '../model/feedback_comment.dart';
import '../model/product.dart';
import '../service/ProductService.dart';
import 'dart:convert';
import 'dart:typed_data';

class ProductDetailPageAdmin extends StatefulWidget {
  final String productId;

  ProductDetailPageAdmin({Key? key, required this.productId}) : super(key: key) {
    assert(productId.isNotEmpty, 'ProductId không được để trống');
  }

  @override
  State<ProductDetailPageAdmin> createState() => _ProductDetailPageAdminState();
}

class _ProductDetailPageAdminState extends State<ProductDetailPageAdmin> {
  final ProductService _productService = ProductService();
  final Set<String> _expandedFeedbacks = {};
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  void _toggleFeedback(String feedbackId) {
    setState(() {
      if (_expandedFeedbacks.contains(feedbackId)) {
        _expandedFeedbacks.remove(feedbackId);
      } else {
        _expandedFeedbacks.add(feedbackId);
      }
    });
  }

  void _showEditProductDialog(Product product) {
    TextEditingController nameController = TextEditingController(text: product.name);
    TextEditingController priceController = TextEditingController(text: product.price.toStringAsFixed(0));
    TextEditingController descriptionController = TextEditingController(text: product.description);
    TextEditingController imageController = TextEditingController(text: product.image ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sửa thông tin sản phẩm'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên sản phẩm',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Giá sản phẩm (VND)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả sản phẩm',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: imageController,
                  decoration: const InputDecoration(
                    labelText: 'URL hình ảnh',
                    border: OutlineInputBorder(),
                  ),
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
              onPressed: () async {
                try {
                  await _database.child('products').child(product.id).update({
                    'name': nameController.text,
                    'price': int.tryParse(priceController.text) ?? product.price,
                    'description': descriptionController.text,
                    'image': imageController.text,
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cập nhật sản phẩm thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khi cập nhật: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Lưu thay đổi'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: StreamBuilder<Product>(
        stream: _productService.getProductStream(widget.productId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Row(
              children: [
                Expanded(child: Text(snapshot.data!.name)),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditProductDialog(snapshot.data!),
                  tooltip: 'Sửa sản phẩm',
                ),
              ],
            );
          }
          return const Text('Loading...');
        },
      ),
    );
  }

  Widget _buildBody() {
    return StreamBuilder<Product>(
      stream: _productService.getProductStream(widget.productId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorView(message: 'Error: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return const LoadingIndicator();
        }

        final product = snapshot.data!;

        if (product.id.isEmpty) {
          return const ErrorView(message: 'Product ID không hợp lệ');
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProductImageSection(product: product),
              ProductInfoSectionAdmin(product: product),
              FeedbackSection(
                productId: widget.productId,
                productService: _productService,
                expandedFeedbacks: _expandedFeedbacks,
                onToggleFeedback: _toggleFeedback,
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProductInfoSectionAdmin extends StatelessWidget {
  final Product product;

  const ProductInfoSectionAdmin({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Info Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            product.description,
            style: TextStyle(
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Price
          Text(
            'Giá',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          Text(
            '${product.price.toStringAsFixed(0)}₫',
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}