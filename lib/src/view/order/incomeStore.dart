import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class RevenueStatisticsScreen extends StatefulWidget {
  @override
  _RevenueStatisticsScreenState createState() => _RevenueStatisticsScreenState();
}

class _RevenueStatisticsScreenState extends State<RevenueStatisticsScreen> {
  final _database = FirebaseDatabase.instance.ref();
  double totalRevenue = 0;
  int totalOrders = 0;
  bool _isLoading = true;
  Map<String, double> dailyRevenue = {};
  Map<String, double> monthlyRevenue = {};

  @override
  void initState() {
    super.initState();
    _calculateRevenue();
  }

  Future<void> _calculateRevenue() async {
    try {
      final ordersSnapshot = await _database.child('orders').get();
      if (ordersSnapshot.exists) {
        double revenue = 0;
        int count = 0;
        final orders = (ordersSnapshot.value as Map<dynamic, dynamic>);

        orders.forEach((key, value) {
          if (value['status'] == 'đã giao') {
            double amount = (value['totalAmount'] ?? 0).toDouble();
            revenue += amount;
            count++;

            DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(value['createdAt']);
            String dayKey = DateFormat('dd/MM/yyyy').format(createdAt);
            String monthKey = DateFormat('MM/yyyy').format(createdAt);

            dailyRevenue[dayKey] = (dailyRevenue[dayKey] ?? 0) + amount;
            monthlyRevenue[monthKey] = (monthlyRevenue[monthKey] ?? 0) + amount;
          }
        });

        setState(() {
          totalRevenue = revenue;
          totalOrders = count;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error calculating revenue: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thống kê doanh thu')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sắp xếp thẻ doanh thu theo chiều dọc
              _buildSummaryCard('Tổng doanh thu', totalRevenue, Colors.green),
              SizedBox(height: 16),
              _buildSummaryCard('Tổng số đơn hàng đã giao', totalOrders.toDouble(), Colors.blue),
              SizedBox(height: 20),

              // Danh sách doanh thu theo ngày
              Text('Doanh thu theo ngày:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildRevenueList(dailyRevenue),
              SizedBox(height: 20),

              // Danh sách doanh thu theo tháng
              Text('Doanh thu theo tháng:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildRevenueList(monthlyRevenue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(
              NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(value),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueList(Map<String, double> revenueData) {
    List<String> sortedKeys = revenueData.keys.toList()..sort((a, b) => b.compareTo(a));
    return Column(
      children: sortedKeys.map((date) {
        return Card(
          elevation: 1,
          child: ListTile(
            title: Text(date, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            trailing: Text(
              NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(revenueData[date]),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
        );
      }).toList(),
    );
  }
}