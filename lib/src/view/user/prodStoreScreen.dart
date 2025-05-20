import 'package:flutter/material.dart';
import 'package:flutter_application_2/src/view/user/productScreen.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../model/feedback.dart' as FeedbackModel;
import '../../model/feedback_comment.dart';
import '../../model/product.dart';
import '../../service/ProductService.dart';
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

    showModalBottomSheet(
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
                          "Sửa thông tin sản phẩm",
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: priceController,
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: imageController,
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
                              SnackBar(
                                content: const Text('Cập nhật sản phẩm thành công!'),
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
                                content: Text('Lỗi khi cập nhật: $e'),
                                backgroundColor: Colors.red[600],
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          "Lưu thay đổi",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
      title: StreamBuilder<Product>(
        stream: _productService.getProductStream(widget.productId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Row(
              children: [
                Expanded(
                  child: Text(
                    snapshot.data!.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.orange[700], size: 28),
                  onPressed: () => _showEditProductDialog(snapshot.data!),
                  tooltip: 'Sửa sản phẩm',
                ),
              ],
            );
          }
          return Text(
            'Loading...',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          );
        },
      ),
      elevation: 0,
      titleSpacing: 16,
      iconTheme: IconThemeData(color: Colors.orange[700]),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: StreamBuilder<Product>(
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
      ),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[900],
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
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Giá',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          Text(
            '${product.price.toStringAsFixed(0)}₫',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.orange[800],
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: Colors.orange[700],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;

  const ErrorView({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red[600],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.red[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}