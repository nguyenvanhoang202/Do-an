import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../../../model/order.dart';
import '../../../model/store.dart';
import '../../feedback/feedbackScreen.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  OrderDetailScreen({required this.order});

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> orderItems = [];
  bool _isLoading = true;
  bool _hasFeedback = false;
  String? _feedbackId;

  @override
  void initState() {
    super.initState();
    _loadOrderItems();
    _checkExistingFeedback();
  }

  Future<void> _loadOrderItems() async {
    try {
      final snapshot = await _database.child('orderItems').child(widget.order.id).get();

      if (snapshot.value != null) {
        final items = (snapshot.value as Map<dynamic, dynamic>).entries;
        final List<Map<String, dynamic>> loadedItems = [];

        for (var item in items) {
          final productId = item.value['productId']?.toString();
          if (productId != null) {
            final productSnapshot = await _database.child('products').child(productId).get();

            if (productSnapshot.value != null) {
              final product = productSnapshot.value as Map<dynamic, dynamic>;
              loadedItems.add({
                'productId': productId,
                'name': product['name']?.toString() ?? 'Sản phẩm',
                'price': (item.value['price'] as num?)?.toDouble() ?? 0,
                'quantity': (item.value['quantity'] as num?)?.toInt() ?? 1,
                'image': product['image']?.toString(),
              });
            }
          }
        }

        setState(() {
          orderItems = loadedItems;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading order items: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkExistingFeedback() async {
    try {
      final snapshot = await _database
          .child('feedbacks')
          .orderByChild('orderId')
          .equalTo(widget.order.id)
          .get();

      if (snapshot.value != null) {
        final feedbacks = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _hasFeedback = true;
          _feedbackId = feedbacks.keys.first.toString();
        });
      }
    } catch (e) {
      print('Error checking feedback: $e');
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    try {
      await _database.child('orders/${widget.order.id}/status').set(newStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật trạng thái đơn hàng')),
      );

      setState(() {
        widget.order.status = newStatus;
      });

      if (newStatus == 'đã giao') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FeedbackScreen(
              order: widget.order,
              orderItems: orderItems,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật: ${e.toString()}')),
      );
    }
  }

  void _navigateToFeedback() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeedbackScreen(
          order: widget.order,
          orderItems: orderItems,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.order.store.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Địa chỉ:', widget.order.store.address),
                    _buildInfoRow('SĐT:', widget.order.store.phoneNumber),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin đơn hàng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Mã đơn:', widget.order.id.substring(0, 8)),
                    _buildInfoRow(
                      'Ngày đặt:',
                      DateFormat('dd/MM/yyyy HH:mm').format(
                        DateTime.fromMillisecondsSinceEpoch(widget.order.createdAt),
                      ),
                    ),
                    _buildInfoRow('Trạng thái:', widget.order.status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin giao hàng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Người nhận:', widget.order.recipientName),
                    _buildInfoRow('Địa chỉ:', widget.order.recipientAddress),
                    if (widget.order.note != null && widget.order.note!.isNotEmpty)
                      _buildInfoRow('Ghi chú:', widget.order.note!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sản phẩm đã đặt',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...orderItems.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: item['image'] != null
                                  ? DecorationImage(
                                image: NetworkImage(item['image']!),
                                fit: BoxFit.cover,
                              )
                                  : null,
                              color: Colors.grey[200],
                            ),
                            child: item['image'] == null
                                ? const Icon(Icons.fastfood, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('Số lượng: ${item['quantity']}'),
                              ],
                            ),
                          ),
                          Text(
                            NumberFormat.currency(
                              locale: 'vi_VN',
                              symbol: '₫',
                            ).format(item['price'] * item['quantity']),
                          ),
                        ],
                      ),
                    )),
                    const Divider(),
                    _buildTotalRow('Tổng tiền:', widget.order.totalAmount),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (widget.order.status == 'mới' || widget.order.status == 'đang xử lý')
              OutlinedButton(
                onPressed: () => _updateOrderStatus('đã hủy'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text(
                  'Hủy đơn',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            if (widget.order.status == 'đang giao')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateOrderStatus('đã hủy'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Hủy đơn', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateOrderStatus('đã giao'),
                      child: const Text('Đã nhận được hàng'),
                    ),
                  ),
                ],
              ),
            if (widget.order.status == 'đã giao')
              ElevatedButton(
                onPressed: _navigateToFeedback,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(
                  _hasFeedback ? 'Sửa đánh giá' : 'Đánh giá đơn hàng',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            NumberFormat.currency(
              locale: 'vi_VN',
              symbol: '₫',
            ).format(amount),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}