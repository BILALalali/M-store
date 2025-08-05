import 'package:flutter/material.dart';
import 'order_model.dart';
import 'order_chat_screen.dart';
import 'product_model.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  // قائمة الطلبات المؤكدة (المحادثات)
  static List<Order> confirmedOrders = [];

  // قائمة المنتجات المؤقتة (قبل التأكيد)
  static List<Product> pendingProducts = [];

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with TickerProviderStateMixin {
  static const Color primaryColor = Color(0xFF1EC6D9);
  static const Color backgroundColor = Color(0xFFF7F7F7);

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // بدء التحريك إذا كانت هناك رسائل غير مقروءة
    if (_hasUnreadMessages()) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardHeight = screenWidth * 0.26;
    final imageSize = screenWidth * 0.18;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(177, 30, 198, 217),
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.png', width: 32, height: 32),
            const SizedBox(width: 8),
            const Text(
              'طلباتي',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // قائمة المنتجات المؤقتة
              Expanded(
                child: OrdersScreen.pendingProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.shopping_cart_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'لا توجد منتجات في قائمة الطلب',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            const SizedBox(height: 24),
                            // زر المحادثات في الشاشة الفارغة
                            if (OrdersScreen.confirmedOrders.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(25),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ConfirmedOrdersScreen(),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color.fromARGB(
                                              255,
                                              46,
                                              131,
                                              141,
                                            ).withOpacity(0.8),
                                            const Color.fromARGB(
                                              143,
                                              30,
                                              198,
                                              217,
                                            ),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color.fromARGB(
                                              255,
                                              187,
                                              100,
                                              100,
                                            ).withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Stack(
                                            children: [
                                              const Icon(
                                                Icons.forum,
                                                color: Color.fromARGB(
                                                  237,
                                                  227,
                                                  248,
                                                  255,
                                                ),
                                                size: 24,
                                              ),
                                              Positioned(
                                                right: -3,
                                                top: -3,
                                                child: Container(
                                                  width: 12,
                                                  height: 12,
                                                  decoration: BoxDecoration(
                                                    color: _hasUnreadMessages()
                                                        ? Colors.red
                                                        : Colors.orange,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'عرض المحادثات (${OrdersScreen.confirmedOrders.length})',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 8,
                        ),
                        itemCount: OrdersScreen.pendingProducts.length,
                        itemBuilder: (context, index) {
                          final product = OrdersScreen.pendingProducts[index];
                          return PendingProductCard(
                            product: product,
                            cardHeight: cardHeight,
                            imageSize: imageSize,
                            onRemove: () {
                              setState(() {
                                OrdersScreen.pendingProducts.removeAt(index);
                              });
                            },
                          );
                        },
                      ),
              ),
              // زر تأكيد الطلب مع إجمالي المبلغ
              if (OrdersScreen.pendingProducts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'إجمالي الطلب:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Text(
                            '${_calculateTotal().toStringAsFixed(2)} ل.س',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 51, 116, 123),
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            _confirmOrder(context);
                          },
                          child: const Text(
                            'تأكيد الطلب',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Cairo',
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // أيقونة المحادثة الخارجة من الشاشة
          Positioned(
            bottom: OrdersScreen.pendingProducts.isNotEmpty ? 140 : 20,
            right: 15,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(35),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ConfirmedOrdersScreen()),
                  );
                },
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _hasUnreadMessages() ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(
                            color: const Color.fromARGB(255, 30, 198, 217),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: const Color.fromARGB(
                                188,
                                177,
                                241,
                                249,
                              ).withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            const Center(
                              child: Icon(
                                Icons.forum,
                                color: Color.fromARGB(198, 75, 188, 202),
                                size: 49,
                              ),
                            ),
                            // شارة الإشعار الخارجة
                            if (OrdersScreen.confirmedOrders.isNotEmpty)
                              Positioned(
                                right: -3,
                                top: -3,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade500,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${OrdersScreen.confirmedOrders.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotal() {
    return OrdersScreen.pendingProducts.fold(
      0.0,
      (sum, product) => sum + product.price,
    );
  }

  void _confirmOrder(BuildContext context) {
    if (OrdersScreen.pendingProducts.isEmpty) return;

    // تحديد نوع الطلب بناءً على المنتجات
    OrderType orderType = OrderType.retail;
    if (OrdersScreen.pendingProducts.any((p) => p.category == 'تحويل رصيد')) {
      orderType = OrderType.mobileCredit;
    } else if (OrdersScreen.pendingProducts.any(
      (p) => p.category == 'خدمات التوصيل',
    )) {
      orderType = OrderType.delivery;
    } else if (OrdersScreen.pendingProducts.length > 1) {
      orderType = OrderType.wholesale;
    }

    // إنشاء طلب واحد يحتوي على جميع المنتجات
    final order = Order(
      productName: OrdersScreen.pendingProducts.map((p) => p.name).join(', '),
      productImage: OrdersScreen.pendingProducts.first.images.isNotEmpty
          ? OrdersScreen.pendingProducts.first.images.first
          : '',
      productId: OrdersScreen.pendingProducts.map((p) => p.name).join('_'),
      productUrl: '',
      date: DateTime.now(),
      status: OrderStatus.pending,
      userName: 'المستخدم الحالي',
      orderType: orderType,
    );

    // إضافة الطلب إلى قائمة الطلبات المؤكدة
    OrdersScreen.confirmedOrders.add(order);

    // مسح قائمة المنتجات المؤقتة
    OrdersScreen.pendingProducts.clear();

    // عرض رسالة نجاح
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم تأكيد الطلب بنجاح! يمكنك الوصول للمحادثة من زر المحادثات',
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );

    // تحديث الواجهة
    setState(() {});
  }

  bool _hasUnreadMessages() {
    // محاكاة وجود رسائل غير مقروءة
    return OrdersScreen.confirmedOrders.isNotEmpty;
  }
}

class PendingProductCard extends StatelessWidget {
  final Product product;
  final double cardHeight;
  final double imageSize;
  final VoidCallback onRemove;

  const PendingProductCard({
    super.key,
    required this.product,
    required this.cardHeight,
    required this.imageSize,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.07),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // صورة المنتج
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: product.images.isNotEmpty
                ? Image.network(
                    product.images.first,
                    width: imageSize,
                    height: imageSize,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: imageSize,
                      height: imageSize,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image,
                        size: 28,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Container(
                    width: imageSize,
                    height: imageSize,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image,
                      size: 28,
                      color: Colors.grey,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // تفاصيل المنتج
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Cairo',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.category,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.price.toStringAsFixed(2)} ل.س',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1EC6D9),
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          // زر الحذف
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            tooltip: 'إزالة من الطلب',
          ),
        ],
      ),
    );
  }
}

class ConfirmedOrdersScreen extends StatelessWidget {
  const ConfirmedOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardHeight = screenWidth * 0.26;
    final imageSize = screenWidth * 0.18;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 76, 130, 136),
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.message, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 8),
            const Text(
              'المحادثات',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
      body: OrdersScreen.confirmedOrders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.message, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد محادثات',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'قم بتأكيد طلب لبدء محادثة',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              itemCount: OrdersScreen.confirmedOrders.length,
              itemBuilder: (context, index) {
                final order = OrdersScreen.confirmedOrders[index];
                return ChatCard(
                  order: order,
                  cardHeight: cardHeight,
                  imageSize: imageSize,
                );
              },
            ),
    );
  }
}

class ChatCard extends StatelessWidget {
  final Order order;
  final double cardHeight;
  final double imageSize;

  const ChatCard({
    super.key,
    required this.order,
    required this.cardHeight,
    required this.imageSize,
  });

  Color getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.pending:
      default:
        return Colors.orange;
    }
  }

  IconData getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
      case OrderStatus.pending:
      default:
        return Icons.schedule;
    }
  }

  String getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return 'تم التأكيد';
      case OrderStatus.cancelled:
        return 'تم الإلغاء';
      case OrderStatus.pending:
      default:
        return 'قيد المراجعة';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderChatScreen(order: order)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          // إضافة حدود مميزة لطلبات الجملة والتوصيل
          border: order.orderType == OrderType.wholesale
              ? Border.all(color: const Color(0xFF1EC6D9), width: 2)
              : order.orderType == OrderType.delivery
              ? Border.all(color: const Color(0xFF2E3A59), width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رأس البطاقة
            Row(
              children: [
                // أيقونة المحادثة
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: order.orderType == OrderType.wholesale
                            ? const Color(0xFF1EC6D9).withOpacity(0.2)
                            : order.orderType == OrderType.delivery
                            ? const Color(0xFF2E3A59).withOpacity(0.2)
                            : order.orderType == OrderType.mobileCredit
                            ? const Color(0xFF4CAF50).withOpacity(0.2)
                            : const Color(0xFF1EC6D9).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        order.orderType == OrderType.wholesale
                            ? Icons.local_shipping
                            : order.orderType == OrderType.delivery
                            ? Icons.local_shipping
                            : order.orderType == OrderType.mobileCredit
                            ? Icons.phone_android
                            : Icons.chat_bubble_outline,
                        color: order.orderType == OrderType.delivery
                            ? const Color(0xFF2E3A59)
                            : order.orderType == OrderType.mobileCredit
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF1EC6D9),
                        size: 24,
                      ),
                    ),
                    if (order.hasUnreadMessages)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                // تفاصيل الطلب
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'طلب بتاريخ ${order.date.day}/${order.date.month}/${order.date.year}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          if (order.orderType == OrderType.wholesale) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1EC6D9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'جملة',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ] else if (order.orderType == OrderType.delivery) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E3A59),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'شحن',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ] else if (order.orderType ==
                              OrderType.mobileCredit) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'رصيد',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.productName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontFamily: 'Cairo',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // إضافة تفاصيل إضافية لطلبات الجملة والتوصيل
                      if (order.orderType == OrderType.wholesale &&
                          order.quantity != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'الكمية: ${order.quantity}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1EC6D9),
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else if (order.orderType == OrderType.delivery &&
                          order.description != null) ...[
                        const SizedBox(height: 4),
                        // استخراج الوزن من الوصف
                        Builder(
                          builder: (context) {
                            final weightMatch = RegExp(
                              r'الوزن: (\d+) كغ',
                            ).firstMatch(order.description!);
                            final locationMatch = RegExp(
                              r'الموقع: (.+)',
                            ).firstMatch(order.description!);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (weightMatch != null)
                                  Text(
                                    'الوزن: ${weightMatch.group(1)} كغ',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF2E3A59),
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                if (locationMatch != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'الموقع: ${locationMatch.group(1)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF2E3A59),
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                // حالة الطلب
                Column(
                  children: [
                    Icon(
                      getStatusIcon(order.status),
                      color: getStatusColor(order.status),
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      getStatusText(order.status),
                      style: TextStyle(
                        fontSize: 12,
                        color: getStatusColor(order.status),
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // خط فاصل
            Container(height: 1, color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 12),
            // زر فتح المحادثة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderType == OrderType.wholesale
                      ? 'متابعة طلب الجملة'
                      : order.orderType == OrderType.delivery
                      ? 'متابعة طلب الشحن'
                      : order.orderType == OrderType.mobileCredit
                      ? 'متابعة طلب الرصيد'
                      : 'فتح المحادثة',
                  style: const TextStyle(
                    color: Color.fromARGB(255, 48, 161, 169),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: const Color.fromARGB(255, 127, 222, 232),
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
