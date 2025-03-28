import 'package:flutter/material.dart';
import 'order/incomeStore.dart';
import 'order/listoderStore.dart';
import 'productStore.dart';
import 'profile/Storeprofilescreen.dart';
import 'storeInfor.dart';

class StoreHomePage extends StatefulWidget {
  @override
  _StoreHomePageState createState() => _StoreHomePageState();
}

class _StoreHomePageState extends State<StoreHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        children: [
          StoreInfoScreen(),
          ProductListScreen(),
          StoreOrdersScreen(),
          RevenueStatisticsScreen(),
          StoreProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.orange,
        child: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.store_outlined), text: "Cửa hàng"),
            Tab(icon: Icon(Icons.fastfood_outlined), text: "Danh mục"),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: "Đơn hàng"),
            Tab(icon: Icon(Icons.attach_money_outlined), text: "Thu nhập"),
            Tab(icon: Icon(Icons.person_outline), text: "Tài khoản"),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orange,
        ),
      ),
    );
  }
}
