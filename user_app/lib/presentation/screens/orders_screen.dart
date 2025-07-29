import 'package:flutter/material.dart';
import 'order_model.dart';
import 'orders_screen.dart';
import 'chat_screen.dart';
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

class _OrdersScreenState extends State<OrdersScreen> {
  static const Color primaryColor = Color(0xFF1EC6D9);
  static const Color backgroundColor = Color(0xFFF7F7F7);
  static const Color beigeColor = Color(0xFFF5EEDC);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardHeight = screenWidth * 0.26;
    final imageSize = screenWidth * 0.18;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
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
        actions: [
          // زر المحادثات
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.chat_bubble_outline, color: Colors.white),
                if (OrdersScreen.confirmedOrders.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _hasUnreadMessages()
                            ? Colors.red
                            : Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ConfirmedOrdersScreen()),
              );
            },
            tooltip: 'المحادثات',
          ),
        ],
      ),
      body: Column(
        children: [
          // قائمة المنتجات المؤقتة
          Expanded(
            child: OrdersScreen.pendingProducts.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد منتجات في قائمة الطلب',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontFamily: 'Cairo',
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
                    color: Colors.grey.withOpacity(0.1),
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
                          color: primaryColor,
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

  void _showConfirmedOrders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ConfirmedOrdersScreen()),
    );
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
        backgroundColor: const Color(0xFF1EC6D9),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'المحادثات',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Cairo',
          ),
        ),
      ),
      body: OrdersScreen.confirmedOrders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
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
          MaterialPageRoute(builder: (_) => ChatScreen(order: order)),
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
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                        color: const Color(0xFF1EC6D9).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline,
                        color: Color(0xFF1EC6D9),
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
                      Text(
                        'طلب بتاريخ ${order.date.day}/${order.date.month}/${order.date.year}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Cairo',
                        ),
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
                  'اضغط لفتح المحادثة',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Cairo',
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1EC6D9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'فتح',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  final double cardHeight;
  final double imageSize;
  const OrderCard({
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
        return Icons.check_box;
      case OrderStatus.cancelled:
        return Icons.cancel;
      case OrderStatus.pending:
      default:
        return Icons.hourglass_bottom;
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
        return 'قيد الاستجابة';
    }
  }

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
          // دائرة العدد
          Container(
            width: imageSize * 0.7,
            height: imageSize * 0.7,
            decoration: BoxDecoration(
              color: const Color(0xFFF44336),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              '1',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // تفاصيل الطلب
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Cairo',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: order.productImage.isNotEmpty
                          ? Image.network(
                              order.productImage,
                              width: imageSize,
                              height: imageSize,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
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
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.userName} - بائع',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontFamily: 'Cairo',
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${order.date.day}/${order.date.month}/${order.date.year}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black38,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      getStatusIcon(order.status),
                      color: getStatusColor(order.status),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      getStatusText(order.status),
                      style: TextStyle(
                        fontSize: 13,
                        color: getStatusColor(order.status),
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
