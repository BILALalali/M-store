import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'account_screen.dart';
import 'orders_screen.dart';
import 'store_screen.dart';
import 'balance_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2; // الرئيسية في المنتصف

  final List<Widget> _screens = const [
    AccountScreen(),
    OrdersScreen(),
    HomeScreen(),
    StoreScreen(),
    BalanceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 13,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'حسابي',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'طلباتي',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_sharp),
            label: 'مخزن الجملة',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            label: 'متجر المفرق',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'شحن أرصدة',
          ),
        ],
      ),
    );
  }
}
