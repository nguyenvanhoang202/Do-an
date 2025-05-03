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

  @override
  void initState() {
    super.initState();
    _loadOrderItems();
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

  Future<void> _updateOrderStatus(String newStatus) async {
    try {
      await _database.child('orders/${widget.order.id}/status').set(newStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật trạng thái đơn hàng')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết đơn hàng'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin cửa hàng
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.order.store.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildInfoRow('Địa chỉ:', widget.order.store.address),
                    _buildInfoRow('SĐT:', widget.order.store.phoneNumber),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Thông tin đơn hàng
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin đơn hàng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
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

            SizedBox(height: 16),

            // Thông tin giao hàng
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin giao hàng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildInfoRow('Người nhận:', widget.order.recipientName),
                    _buildInfoRow('Địa chỉ:', widget.order.recipientAddress),
                    if (widget.order.note != null && widget.order.note!.isNotEmpty)
                      _buildInfoRow('Ghi chú:', widget.order.note!),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Chi tiết sản phẩm
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sản phẩm đã đặt',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    ...orderItems.map((item) => Padding(
                      padding: EdgeInsets.only(bottom: 12),
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
                                ? Icon(Icons.fastfood, color: Colors.grey)
                                : null,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  style: TextStyle(fontWeight: FontWeight.bold),
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
                    Divider(),
                    _buildTotalRow('Tổng tiền:', widget.order.totalAmount),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Nút hành động
            if (widget.order.status == 'mới' || widget.order.status == 'đang xử lý')
              OutlinedButton(
                onPressed: () => _updateOrderStatus('đã hủy'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red),
                  minimumSize: Size(double.infinity, 48),
                ),
                child: Text(
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
                        side: BorderSide(color: Colors.red),
                      ),
                      child: Text('Hủy đơn', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateOrderStatus('đã giao'),
                      child: Text('Đã nhận được hàng'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
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
              style: TextStyle(
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
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            NumberFormat.currency(
              locale: 'vi_VN',
              symbol: '₫',
            ).format(amount),
            style: TextStyle(
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