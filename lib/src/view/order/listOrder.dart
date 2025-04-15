import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../model/order.dart';
import '../../model/user.dart' as app_user;
import '../../model/store.dart';
import 'orderDetail.dart';

class OrdersTab extends StatefulWidget {
  @override
  _OrdersTabState createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> with TickerProviderStateMixin {
  final _database = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;
  late TabController _tabController;
  List<Order> _activeOrders = [];
  List<Order> _completedOrders = [];
  List<Order> _canceledOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  void _loadOrders() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _database
        .child('orders')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .listen((event) async {
      if (event.snapshot.value == null) {
        setState(() {
          _activeOrders = [];
          _completedOrders = [];
          _canceledOrders = [];
        });
        return;
      }

      try {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        print('Found orders: ${data.length}');

        // Lấy thông tin users và stores
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

            print('Processing order: ${entry.key}, storeId: $storeId, userId: $userId');

            if (storeId != null && userId != null) {
              final store = stores[storeId];
              final user = users[userId];

              if (store != null && user != null) {
                // Xử lý trạng thái đơn hàng
                String status = orderData['status']?.toString()?.toLowerCase() ?? '';
                String displayStatus = status;

                // Nếu trạng thái là 'mới' hoặc rỗng, hiển thị là 'chờ xác nhận'
                if (status.isEmpty || status == 'mới') {
                  displayStatus = 'chờ xác nhận';
                }

                final order = Order(
                  id: entry.key,
                  user: user,
                  store: store,
                  note: orderData['note']?.toString(),
                  status: displayStatus,
                  paymentMethod: PaymentMethod.cashOnDelivery,
                  totalAmount: (orderData['totalAmount'] as num).toDouble(),
                  shippingFee: (orderData['shippingFee'] as num?)?.toDouble() ?? 0.0,
                  recipientName: orderData['recipientName']?.toString() ?? '',
                  recipientAddress: orderData['recipientAddress']?.toString() ?? '',
                  createdAt: orderData['createdAt'] as int,
                );
                loadedOrders.add(order);
              }
            }
          } catch (e) {
            print('Error processing order ${entry.key}: $e');
          }
        }

        // Sắp xếp theo thời gian mới nhất
        loadedOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Phân loại đơn hàng
        setState(() {
          _activeOrders = loadedOrders.where((o) =>
          o.status == 'chờ xác nhận' || o.status == 'đang giao').toList();
          _completedOrders = loadedOrders.where((o) =>
          o.status == 'đã giao').toList();
          _canceledOrders = loadedOrders.where((o) =>
          o.status == 'đã hủy').toList();
          _isLoading = false;
        });

        print('Loaded ${loadedOrders.length} orders');
      } catch (e) {
        print('Error loading orders: $e');
        setState(() => _isLoading = false);
      }
    });
  }

  Future<String?> _getFirstProductImage(String orderId) async {
    try {
      final snapshot = await _database.child('orderItems').child(orderId).get();
      if (snapshot.value != null) {
        final items = (snapshot.value as Map<dynamic, dynamic>).values;
        if (items.isNotEmpty) {
          final firstItem = items.first;
          final productId = firstItem['productId']?.toString();
          if (productId != null) {
            final productSnapshot = await _database.child('products').child(productId).get();
            return productSnapshot.child('image').value?.toString();
          }
        }
      }
    } catch (e) {
      print('Error getting product image: $e');
    }
    return null;
  }

  Future<String?> _getFirstProductName(String orderId) async {
    try {
      final snapshot = await _database.child('orderItems').child(orderId).get();
      if (snapshot.value != null) {
        final items = (snapshot.value as Map<dynamic, dynamic>).values;
        if (items.isNotEmpty) {
          final firstItem = items.first;
          final productId = firstItem['productId']?.toString();
          if (productId != null) {
            final productSnapshot = await _database.child('products').child(productId).get();
            return productSnapshot.child('name').value?.toString();
          }
        }
      }
    } catch (e) {
      print('Error getting product name: $e');
    }
    return null;
  }

  Widget _buildOrderItem(Order order) {
    return FutureBuilder(
      future: Future.wait([
        _getFirstProductImage(order.id),
        _getFirstProductName(order.id),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        final productImage = snapshot.hasData ? snapshot.data![0] as String? : null;
        final productName = snapshot.hasData ? snapshot.data![1] as String? : 'Đang tải...';

        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailScreen(order: order),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  // Ảnh sản phẩm
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                      image: productImage != null
                          ? DecorationImage(
                        image: NetworkImage(productImage),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: productImage == null
                        ? Icon(Icons.fastfood, color: Colors.grey)
                        : null,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName ?? 'Không có tên sản phẩm',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Mã đơn: ${order.id.substring(0, 8)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        SizedBox(height: 8),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(
                              DateTime.fromMillisecondsSinceEpoch(order.createdAt)),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                order.status,
                                style: TextStyle(
                                  color: _getStatusColor(order.status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              NumberFormat.currency(
                                locale: 'vi_VN',
                                symbol: '₫',
                              ).format(order.totalAmount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
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
      case 'chờ xác nhận':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Đơn hàng của tôi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange[800],
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.orange,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.orange,
              tabs: [
                Tab(text: 'Đang xử lý'),
                Tab(text: 'Đã hoàn thành'),
                Tab(text: 'Đã hủy'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderListView(_activeOrders),
                _buildOrderListView(_completedOrders),
                _buildOrderListView(_canceledOrders),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderListView(List<Order> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Text('Không có đơn hàng nào'),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => _loadOrders(),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 8),
        itemCount: orders.length,
        itemBuilder: (context, index) => _buildOrderItem(orders[index]),
      ),
    );
  }
}