import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RevenueStatisticsScreen extends StatefulWidget {
  @override
  _RevenueStatisticsScreenState createState() => _RevenueStatisticsScreenState();
}

class _RevenueStatisticsScreenState extends State<RevenueStatisticsScreen> {
  final _database = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;
  double totalRevenue = 0;
  int totalOrders = 0;
  bool _isLoading = true;
  Map<String, double> dailyRevenue = {};
  Map<String, double> monthlyRevenue = {};
  Map<String, List<Map<dynamic, dynamic>>> dailyOrders = {};
  Map<String, List<Map<dynamic, dynamic>>> monthlyOrders = {};
  List<Map<dynamic, dynamic>> deliveredOrders = [];
  String? _storeId;

  @override
  void initState() {
    super.initState();
    _getStoreIdAndCalculateRevenue();
  }

  Future<void> _getStoreIdAndCalculateRevenue() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        final userSnapshot = await _database.child('users').child(user.uid).get();
        if (userSnapshot.exists) {
          final userData = userSnapshot.value;
          if (userData is Map) {
            final userMap = userData as Map<dynamic, dynamic>;
            if (userMap.containsKey('storeId')) {
              _storeId = userMap['storeId'].toString();
              print('StoreId từ node users: $_storeId');
            } else {
              print('Không tìm thấy key "storeId" trong node users/${user.uid}');
              _storeId = user.uid;
            }
          } else {
            print('Dữ liệu trong node users/${user.uid} không phải là Map: $userData');
            _storeId = user.uid;
          }
        } else {
          print('Không tìm thấy node users/${user.uid} trong Firebase');
          _storeId = user.uid;
        }
        print('StoreId được sử dụng: $_storeId');
        await _calculateRevenue();
      } else {
        print('Người dùng chưa đăng nhập');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Lỗi khi lấy storeId từ node users: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _calculateRevenue() async {
    if (_storeId == null) {
      print('Lỗi: storeId không được thiết lập');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final ordersSnapshot = await _database.child('orders').get();
      if (ordersSnapshot.exists) {
        double revenue = 0;
        int count = 0;
        final orders = ordersSnapshot.value as Map<dynamic, dynamic>;
        print('Tổng số đơn hàng tìm thấy: ${orders.length}');

        // Lặp qua tất cả các đơn hàng
        for (var orderEntry in orders.entries) {
          final orderKey = orderEntry.key;
          final orderValue = orderEntry.value;

          print('Order $orderKey: storeId=${orderValue['storeId']}, expectedStoreId=$_storeId, status=${orderValue['status']}');

          if (orderValue['status'] == 'đã giao' && orderValue['storeId'] == _storeId) {
            if (orderValue['totalAmount'] != null && orderValue['createdAt'] != null) {
              double amount = (orderValue['totalAmount'] is num) ? orderValue['totalAmount'].toDouble() : 0;
              try {
                DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(
                    orderValue['createdAt'] is int ? orderValue['createdAt'] : 0);
                String dayKey = DateFormat('dd/MM/yyyy').format(createdAt);
                String monthKey = DateFormat('MM/yyyy').format(createdAt);

                // Lấy thông tin chi tiết các sản phẩm trong đơn hàng
                final orderItemsSnapshot = await _database.child('orderItems').child(orderKey).get();
                List<Map<String, dynamic>> items = [];

                if (orderItemsSnapshot.exists) {
                  final orderItems = orderItemsSnapshot.value as Map<dynamic, dynamic>;

                  for (var itemEntry in orderItems.entries) {
                    final productId = itemEntry.value['productId']?.toString();
                    if (productId != null) {
                      final productSnapshot = await _database.child('products').child(productId).get();
                      if (productSnapshot.exists) {
                        final product = productSnapshot.value as Map<dynamic, dynamic>;
                        items.add({
                          'productId': productId,
                          'name': product['name']?.toString() ?? 'Sản phẩm',
                          'quantity': (itemEntry.value['quantity'] as num?)?.toInt() ?? 1,
                        });
                      }
                    }
                  }
                }

                revenue += amount;
                count++;
                dailyRevenue[dayKey] = (dailyRevenue[dayKey] ?? 0) + amount;
                monthlyRevenue[monthKey] = (monthlyRevenue[monthKey] ?? 0) + amount;

                final orderData = Map<dynamic, dynamic>.from(orderValue);
                orderData['orderId'] = orderKey;
                orderData['items'] = items; // Thêm thông tin sản phẩm vào đơn hàng
                deliveredOrders.add(orderData);

                dailyOrders.putIfAbsent(dayKey, () => []);
                dailyOrders[dayKey]!.add(orderData);

                monthlyOrders.putIfAbsent(monthKey, () => []);
                monthlyOrders[monthKey]!.add(orderData);

                print('Đơn hàng $orderKey được tính: amount=$amount');
              } catch (e) {
                print('Lỗi định dạng createdAt cho đơn hàng $orderKey: $e');
              }
            } else {
              print('Đơn hàng $orderKey thiếu totalAmount hoặc createdAt');
            }
          } else {
            print('Đơn hàng $orderKey không thỏa mãn: status hoặc storeId không khớp');
          }
        }

        print('Doanh thu: $revenue, Số đơn hàng: $count');
        setState(() {
          totalRevenue = revenue;
          totalOrders = count;
          _isLoading = false;
        });
      } else {
        print('Không tìm thấy đơn hàng trong node orders');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Lỗi khi tính doanh thu: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê doanh thu')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _storeId == null
          ? const Center(child: Text('Không tìm thấy thông tin cửa hàng'))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummaryCard('Tổng doanh thu', totalRevenue, Colors.green, onTap: null),
              const SizedBox(height: 16),
              _buildSummaryCard('Tổng số đơn hàng đã giao', totalOrders.toDouble(), Colors.blue, onTap: () {
                _showOrderListDialog(context, deliveredOrders, 'Danh sách đơn hàng đã giao');
              }),
              const SizedBox(height: 20),
              const Text('Doanh thu theo ngày:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildRevenueList(dailyRevenue, dailyOrders, isDaily: true),
              const SizedBox(height: 20),
              const Text('Doanh thu theo tháng:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildRevenueList(monthlyRevenue, monthlyOrders, isDaily: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double value, Color color, {VoidCallback? onTap}) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                title.contains('Tổng số đơn hàng')
                    ? value.toInt().toString()
                    : NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(value),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueList(Map<String, double> revenueData, Map<String, List<Map<dynamic, dynamic>>> ordersData, {required bool isDaily}) {
    List<String> sortedKeys = revenueData.keys.toList()..sort((a, b) => b.compareTo(a));
    return sortedKeys.isEmpty
        ? const Center(child: Text('Không có dữ liệu doanh thu'))
        : Column(
      children: sortedKeys.map((date) {
        return Card(
          elevation: 1,
          child: ListTile(
            onTap: () {
              _showOrderListDialog(context, ordersData[date]!, 'Đơn hàng ${isDaily ? 'ngày $date' : 'tháng $date'}');
            },
            title: Text(date, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            trailing: Text(
              NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(revenueData[date]),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showOrderListDialog(BuildContext context, List<Map<dynamic, dynamic>> orders, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: orders.isEmpty
                ? const Text('Không có đơn hàng')
                : ListView.builder(
              shrinkWrap: true,
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final items = (order['items'] as List<dynamic>? ?? []) as List<Map<String, dynamic>>;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đơn hàng: ${order['orderId']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        items.isNotEmpty
                            ? Column(
                          children: items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item['name'] ?? 'Món không xác định',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'x${item['quantity'] ?? 1}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        )
                            : const Text(
                          'Không có thông tin chi tiết món hàng',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tổng: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(order['totalAmount'])}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }
}