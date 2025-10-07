import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'account_screen.dart';
import 'orders_screen.dart';
import 'store_screen.dart';
import 'other_services_screen.dart';
import '../../core/services/support_chat_service.dart';
import '../../core/services/message_listener_service.dart';
import '../../core/services/order_chat_service.dart';
import 'order_model.dart';
import 'dart:async';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2; // الرئيسية في المنتصف
  int _unreadSupportMessages = 0;
  StreamSubscription? _unreadSubscription;
  
  // خدمة الاستماع للرسائل
  final MessageListenerService _messageListener = MessageListenerService();

  final List<Widget> _screens = [
    AccountScreen(),
    OrdersScreen(),
    HomeScreen(),
    StoreScreen(),
    OtherServicesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeUnreadCount();
    _initializeMessageListener();
  }

  @override
  void dispose() {
    _unreadSubscription?.cancel();
    _messageListener.dispose();
    super.dispose();
  }
  
  /// تهيئة خدمة الاستماع للرسائل الجديدة
  Future<void> _initializeMessageListener() async {
    try {
      print('🔔 تهيئة خدمة الاستماع للرسائل...');
      
      // تحميل جميع المحادثات
      final results = await Future.wait<List<Order>>([
        OrderChatService.fetchWholesaleOrdersForCurrentUser(),
        OrderChatService.fetchRetailOrdersForCurrentUser(),
      ]);
      
      final List<Order> allOrders = [...results[0], ...results[1]];
      
      if (allOrders.isNotEmpty) {
        // بدء الاستماع لجميع المحادثات
        await _messageListener.startListening(allOrders);
        print('✅ تم بدء الاستماع لـ ${allOrders.length} محادثة');
      } else {
        print('⚠️ لا توجد محادثات للاستماع لها');
      }
    } catch (e) {
      print('❌ خطأ في تهيئة خدمة الاستماع: $e');
    }
  }

  Future<void> _initializeUnreadCount() async {
    // جلب العدد الأولي
    final count = await SupportChatService.getUnreadMessagesCount();
    if (mounted) {
      setState(() {
        _unreadSupportMessages = count;
      });
    }

    // الاشتراك في التحديثات
    _unreadSubscription = await SupportChatService.subscribeToUnreadCount((
      count,
    ) {
      if (mounted) {
        setState(() {
          _unreadSupportMessages = count;
        });
      }
    });
  }

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
                      badge: OrdersScreen.pendingProducts.length,
                      hasPendingOrders: OrdersScreen.confirmedOrders.isNotEmpty,
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
                      icon: Icons.widgets_outlined, // أيقونة خدمات متنوعة
                      label: 'خدمات أخرى',
                      index: 4,
                      selected: _currentIndex == 4,
                      primaryColor: primaryColor,
                      badge: _unreadSupportMessages,
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
    int badge = 0,
    bool hasPendingOrders = false,
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
              Stack(
                children: [
                  Icon(
                    icon,
                    size: 26,
                    color: selected ? primaryColor : Colors.black54,
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          badge.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  if (hasPendingOrders && badge == 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
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
