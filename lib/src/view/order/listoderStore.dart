import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../model/order.dart';
import '../../model/user.dart' as app_user;
import '../../model/store.dart';
import 'oderDetailStore.dart';
import 'orderDetail.dart';

class StoreOrdersScreen extends StatefulWidget {
  @override
  _StoreOrdersScreenState createState() => _StoreOrdersScreenState();
}

class _StoreOrdersScreenState extends State<StoreOrdersScreen> with SingleTickerProviderStateMixin {
  final _database = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;
  late TabController _tabController;
  List<Order> _allOrders = [];
  List<Order> _newOrders = [];
  List<Order> _deliveringOrders = [];
  List<Order> _completedOrders = [];
  List<Order> _canceledOrders = []; // Thêm danh sách đơn đã hủy
  String? _storeId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Đổi thành 4 tab
    _loadStoreId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadStoreId() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final userSnapshot = await _database.child('users/$userId/storeId').get();
    if (userSnapshot.exists) {
      setState(() {
        _storeId = userSnapshot.value.toString();
      });
      _loadOrders();
    }
  }

  void _loadOrders() {
    if (_storeId == null) return;

    _database
        .child('orders')
        .orderByChild('storeId')
        .equalTo(_storeId)
        .onValue
        .listen((event) async {
      if (event.snapshot.value == null) {
        _clearOrders();
        return;
      }

      try {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final usersSnapshot = await _database.child('users').get();
        final storesSnapshot = await _database.child('stores').get();

        final users = <String, app_user.User>{};
        final stores = <String, Store>{};

        if (usersSnapshot.value != null) {
          final usersData = usersSnapshot.value as Map<dynamic, dynamic>;
          usersData.forEach((key, value) {
            users[key.toString()] = app_user.User(
              id: key.toString(),
              name: value['name'] ?? '',
              email: value['email'] ?? '',
              phone: value['phone'] ?? '',
            );
          });
        }

        if (storesSnapshot.value != null) {
          final storesData = storesSnapshot.value as Map<dynamic, dynamic>;
          storesData.forEach((key, value) {
            stores[key.toString()] = Store(
              id: key.toString(),
              name: value['name'] ?? '',
              description: value['description'] ?? '',
              phoneNumber: value['phoneNumber'] ?? '',
              address: value['address'] ?? '',
              status: value['status'] ?? '',
              rating: (value['rating'] as num?)?.toDouble() ?? 0.0,
            );
          });
        }

        final loadedOrders = <Order>[];

        for (var entry in data.entries) {
          try {
            final orderData = Map<String, dynamic>.from(entry.value as Map);
            final storeId = orderData['storeId']?.toString();
            final userId = orderData['userId']?.toString();

            if (storeId != null && userId != null) {
              final store = stores[storeId];
              final user = users[userId];

              if (store != null && user != null) {
                final order = Order(
                  id: entry.key,
                  user: user,
                  store: store,
                  note: orderData['note']?.toString(),
                  status: orderData['status']?.toString() ?? 'mới',
                  paymentMethod: PaymentMethod.cashOnDelivery,
                  totalAmount: (orderData['totalAmount'] as num).toDouble(),
                  shippingFee: (orderData['shippingFee'] as num?)?.toDouble() ??
                      0.0,
                  recipientName: orderData['recipientName']?.toString() ?? '',
                  recipientAddress: orderData['recipientAddress']?.toString() ??
                      '',
                  createdAt: orderData['createdAt'] as int,
                );
                loadedOrders.add(order);
              }
            }
          } catch (e) {
            print('Error processing order ${entry.key}: $e');
          }
        }

        loadedOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _categorizeOrders(loadedOrders);
      } catch (e) {
        print('Error loading orders: $e');
        _clearOrders();
      }
    });
  }

  void _categorizeOrders(List<Order> orders) {
    setState(() {
      _allOrders = orders;
      _newOrders =
          orders.where((o) => o.status.toLowerCase() == 'mới').toList();
      _deliveringOrders =
          orders.where((o) => o.status.toLowerCase() == 'đang giao').toList();
      _completedOrders =
          orders.where((o) => o.status.toLowerCase() == 'đã giao').toList();
      _canceledOrders = orders
          .where((o) => o.status.toLowerCase() == 'đã hủy')
          .toList(); // Thêm phân loại đơn hủy
    });
  }

  void _clearOrders() {
    setState(() {
      _allOrders = [];
      _newOrders = [];
      _deliveringOrders = [];
      _completedOrders = [];
      _canceledOrders = []; // Clear danh sách đơn hủy
    });
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _database.child('orders/$orderId/status').set(newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật trạng thái đơn hàng')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật: $e')),
      );
    }
  }


  Widget _buildOrderList(List<Order> orders, {bool showActions = false}) {
    if (orders.isEmpty) {
      return Center(
        child: Text('Không có đơn hàng nào'),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.0),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final statusColor = _getStatusColor(order.status);
        final statusIcon = _getStatusIcon(order.status);

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoreOrderDetailScreen(order: order),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(statusIcon, color: statusColor),
                    ),
                    title: Text('Đơn hàng #${order.id.substring(0, 8)}'),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(
                          DateTime.fromMillisecondsSinceEpoch(order.createdAt)),
                    ),
                    trailing: Chip(
                      label: Text(
                        order.status,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      backgroundColor: statusColor,
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tổng tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(order.totalAmount)}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  // Nút cho đơn mới
                  if (showActions && order.status.toLowerCase() == 'mới')
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _updateOrderStatus(order.id, 'đã hủy'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red),
                            ),
                            child: Text('Hủy', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateOrderStatus(order.id, 'đang giao'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: Text('Xác nhận'),
                          ),
                        ),
                      ],
                    ),

                  // Nút cho đơn đang giao
                  if (order.status.toLowerCase() == 'đang giao')
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: Icon(Icons.phone, size: 16, color: Colors.white),
                              label: Text('Shipper', style: TextStyle(color: Colors.white)),
                              onPressed: () => null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.phone, size: 16, color: Colors.white),
                              label: Text('Gọi khách', style: TextStyle(color: Colors.white)),
                              onPressed: () => null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
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
      default:
        return Colors.orange;
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
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Màu nền tổng thể
      appBar: AppBar(
        title: Text('Quản lý đơn hàng',
            style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.grey[100], // Màu nền giống body
        elevation: 0, // Bỏ đổ bóng
        iconTheme: IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Container(
            color: Colors.grey[100], // Màu nền giống body
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              indicatorColor: Colors.orange, // Thanh trượt màu cam
              labelColor: Colors.black87,
              unselectedLabelColor: Colors.grey[600],
              indicatorWeight: 3,
              tabs: [
                Tab(
                  icon: Icon(Icons.access_time, size: 20),
                  text: 'Mới',
                ),
                Tab(
                  icon: Icon(Icons.local_shipping, size: 20),
                  text: 'Đang giao',
                ),
                Tab(
                  icon: Icon(Icons.check_circle, size: 20),
                  text: 'Hoàn thành',
                ),
                Tab(
                  icon: Icon(Icons.cancel, size: 20),
                  text: 'Đã hủy',
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.grey[100], // Đảm bảo đồng nhất màu nền
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOrderList(_newOrders, showActions: true),
            _buildOrderList(_deliveringOrders),
            _buildOrderList(_completedOrders),
            _buildOrderList(_canceledOrders),
          ],
        ),
      ),
    );
  }
}