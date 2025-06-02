import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../../../model/order.dart';
import '../../../model/user.dart' as app_user;

class StoreOrderDetailScreen extends StatefulWidget {
  final Order order;

  StoreOrderDetailScreen({required this.order});

  @override
  _StoreOrderDetailScreenState createState() => _StoreOrderDetailScreenState();
}

class _StoreOrderDetailScreenState extends State<StoreOrderDetailScreen> {
  final _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> orderItems = [];
  bool _isLoading = true;
  app_user.User? _customer;

  @override
  void initState() {
    super.initState();
    _loadOrderData();
  }
  // load orderitem, lấy chi tiết các thông tin sản phẩm, khách hàng
  Future<void> _loadOrderData() async {
    try {
      // Load order items
      final itemsSnapshot = await _database.child('orderItems').child(widget.order.id).get();
      if (itemsSnapshot.value != null) {
        final items = (itemsSnapshot.value as Map<dynamic, dynamic>).entries;
        final List<Map<String, dynamic>> loadedItems = [];

        for (var item in items) {
          final productId = item.value['productId'];
          final productSnapshot = await _database.child('products').child(productId).get();

          if (productSnapshot.value != null) {
            final product = productSnapshot.value as Map<dynamic, dynamic>;
            loadedItems.add({
              'productId': productId,
              'name': product['name'],
              'price': item.value['price'],
              'quantity': item.value['quantity'],
              'image': product['image'],
            });
          }
        }

        setState(() {
          orderItems = loadedItems;
        });
      }

      // Load customer info
      final userSnapshot = await _database.child('users').child(widget.order.user.id).get();
      if (userSnapshot.value != null) {
        final userData = userSnapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _customer = app_user.User(
            id: widget.order.user.id,
            name: userData['name'] ?? 'Khách hàng',
            email: userData['email'] ?? '',
            phone: userData['phone'] ?? '',
          );
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading order data: $e');
      setState(() => _isLoading = false);
    }
  }
  //hiển thị thông báo khi trạng thái thay đổi
  Future<void> _updateOrderStatus(String newStatus) async {
    try {
      await _database
          .child('orders')
          .child(widget.order.id)
          .update({'status': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật trạng thái thành công!')),
      );

      Navigator.pop(context, true);
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
        title: Text('Chi tiết đơn hàng #${widget.order.id.substring(0, 8)}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin khách hàng
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin khách hàng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.person, color: Colors.blue),
                      title: Text(_customer?.name ?? 'Khách hàng'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_customer?.phone != null)
                            Text('SĐT: ${_customer?.phone}'),
                          if (_customer?.email != null)
                            Text('Email: ${_customer?.email}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Thông tin giao hàng
            Card(
              elevation: 2,
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
                    _buildInfoRow(
                      'Thời gian đặt:',
                      DateFormat('dd/MM/yyyy HH:mm').format(
                        DateTime.fromMillisecondsSinceEpoch(widget.order.createdAt),
                      ),
                    ),
                    if (widget.order.note != null && widget.order.note!.isNotEmpty)
                      _buildInfoRow('Ghi chú:', widget.order.note!),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Chi tiết đơn hàng
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chi tiết đơn hàng',
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
                                image: NetworkImage(item['image']),
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
                              decimalDigits: 0,
                            ).format(item['price'] * item['quantity']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Trạng thái và nút xác nhận
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trạng thái đơn hàng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(widget.order.status),
                          color: _getStatusColor(widget.order.status),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.order.status,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(widget.order.status),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Nút cho đơn mới
                    if (widget.order.status == 'mới')
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _updateOrderStatus('đã hủy'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text(
                                'Từ chối đơn',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateOrderStatus('đang giao'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Xác nhận đơn'),
                            ),
                          ),
                        ],
                      ),



                    // Nút cho đơn đang giao
                    if (widget.order.status == 'đang giao')
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: null, // Vô hiệu hóa
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Gọi cho khách'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: null, // Vô hiệu hóa
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Gọi cho shipper'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'đã giao':
        return Colors.green;
      case 'đã hủy':
        return Colors.red;
      case 'đang giao':
        return Colors.blue;
      case 'đang xử lý':
        return Colors.orange;
      case 'mới':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'đã giao':
        return Icons.check_circle;
      case 'đã hủy':
        return Icons.cancel;
      case 'đang giao':
        return Icons.local_shipping;
      case 'đang xử lý':
        return Icons.hourglass_top;
      case 'mới':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }
}