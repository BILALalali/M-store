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

  final List<Widget> _screens = [
    AccountScreen(),
    OrdersScreen(),
    HomeScreen(),
    StoreScreen(),
    BalanceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // ألوان الهوية البصرية
    const Color primaryColor = Color(0xFF6FD8E8); // فيروزي أفتح
    const Color beigeColor = Color(0xFFFAF6EF); // سكري أفتح
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
        child: SizedBox(
          height: 72, // تقليل الارتفاع الكلي
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // خلفية الشريط السفلي
              Container(
                height: 64, // تقليل ارتفاع الشريط
                decoration: BoxDecoration(
                  color: beigeColor,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      icon: Icons.person_outline,
                      label: 'حسابي',
                      index: 0,
                      selected: _currentIndex == 0,
                      primaryColor: primaryColor,
                    ),
                    _buildNavItem(
                      icon: Icons.receipt_long_outlined,
                      label: 'طلباتي',
                      index: 1,
                      selected: _currentIndex == 1,
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(width: 56), // فراغ لمكان الأيقونة البارزة
                    _buildNavItem(
                      icon: Icons.store_sharp,
                      label: ' بيع الجملة ',
                      index: 3,
                      selected: _currentIndex == 3,
                      primaryColor: primaryColor,
                    ),
                    _buildNavItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'شحن أرصدة',
                      index: 4,
                      selected: _currentIndex == 4,
                      primaryColor: primaryColor,
                    ),
                  ],
                ),
              ),
              // الأيقونة الرئيسية في منتصف الشريط
              Positioned(
                bottom: 4, // الأيقونة داخل الشريط
                child: GestureDetector(
                  onTap: () {
                    setState(() => _currentIndex = 2);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.home_filled,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool selected,
    required Color primaryColor,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: () {
          setState(() => _currentIndex = index);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 26,
                color: selected ? primaryColor : Colors.black54,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? primaryColor : Colors.black54,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
