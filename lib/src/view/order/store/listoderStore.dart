import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../model/order.dart';
import '../../../model/user.dart' as app_user;
import '../../../model/store.dart';
import 'oderDetailStore.dart';

class StoreOrdersScreen extends StatefulWidget {
  @override
  _StoreOrdersScreenState createState() => _StoreOrdersScreenState();
}

class _StoreOrdersScreenState extends State<StoreOrdersScreen>
    with SingleTickerProviderStateMixin {
  final _database = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;
  late TabController _tabController;
  List<Order> _allOrders = [];
  List<Order> _newOrders = [];
  List<Order> _receivedOrders = [];
  List<Order> _completedOrders = [];
  List<Order> _canceledOrders = [];
  String? _storeId;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStoreId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

// lấy storeid, rồi load các đơn hàng
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

  // lấy dữ liệu người dùng và cửa hàng, tạo danh sách đơn hàng
  void _loadOrders() {
    if (_storeId == null) return;
    setState(() => _isLoading = true);
    _database
        .child('orders')
        .orderByChild('storeId')
        .equalTo(_storeId)
        .onValue
        .listen((event) async {
      if (event.snapshot.value == null) {
        _clearOrders();
        setState(() => _isLoading = false);
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
                  shippingFee:
                      (orderData['shippingFee'] as num?)?.toDouble() ?? 0.0,
                  recipientName: orderData['recipientName']?.toString() ?? '',
                  recipientAddress:
                      orderData['recipientAddress']?.toString() ?? '',
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
        setState(() => _isLoading = false);
      } catch (e) {
        print('Error loading orders: $e');
        _clearOrders();
        setState(() => _isLoading = false);
      }
    });
  }

// Phân loại đơn hàng vào các danh mục
  void _categorizeOrders(List<Order> orders) {
    setState(() {
      _allOrders = orders;
      _newOrders =
          orders.where((o) => o.status.toLowerCase() == 'mới').toList();
      _receivedOrders = orders
          .where((o) =>
              o.status.toLowerCase() == 'đang xử lý' ||
              o.status.toLowerCase() == 'đang giao')
          .toList();
      _completedOrders =
          orders.where((o) => o.status.toLowerCase() == 'đã giao').toList();
      _canceledOrders =
          orders.where((o) => o.status.toLowerCase() == 'đã hủy').toList();
    });
  }

  //Xóa tất cả danh sách đơn hàng khi không có dữ liệu
  void _clearOrders() {
    setState(() {
      _allOrders = [];
      _newOrders = [];
      _receivedOrders = [];
      _completedOrders = [];
      _canceledOrders = [];
    });
  }

  // thông báo cập nhật trạng thái đơn trên firebase
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _database.child('orders/$orderId/status').set(newStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật trạng thái đơn hàng')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật: $e')),
      );
    }
  }

  // giao diện hiển thị danh sách đơn hàng, chi tiết đơn hàng
  Widget _buildOrderList(List<Order> orders, {bool showActions = false}) {
    if (orders.isEmpty) {
      return const Center(
        child: Text('Không có đơn hàng nào'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final statusColor = _getStatusColor(order.status);
        final statusIcon = _getStatusIcon(order.status);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
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
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
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
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      backgroundColor: statusColor,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tổng tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(order.totalAmount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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

//  xét màu cho các status
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

// xét icon cho các status
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

  // giao diện chính
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Quản lý đơn hàng',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            )),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              indicatorColor: Colors.orange,
              labelColor: Colors.black87,
              unselectedLabelColor: Colors.grey[600],
              indicatorWeight: 3,
              tabs: const [
                Tab(
                    icon: Icon(Icons.access_time, size: 20),
                    child: Text('Mới',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Tab(
                    icon: Icon(Icons.inventory, size: 20),
                    child: Text('Đã nhận',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Tab(
                    icon: Icon(Icons.check_circle, size: 20),
                    child: Text('Đã giao',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Tab(
                    icon: Icon(Icons.cancel, size: 20),
                    child: Text('Đã hủy',
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: Colors.grey[100],
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderList(_newOrders, showActions: true),
                  _buildOrderList(_receivedOrders),
                  _buildOrderList(_completedOrders),
                  _buildOrderList(_canceledOrders),
                ],
              ),
            ),
    );
  }
}
