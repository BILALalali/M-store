import 'package:flutter/material.dart';
import 'order_model.dart';
import 'orders_screen.dart';
import 'chat_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  static List<Order> orders = [];

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const Color primaryColor = Color(0xFF1EC6D9);
  static const Color backgroundColor = Color(0xFFF7F7F7);

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
      ),
      body: FutureBuilder(
        future: Future.value(true),
        builder: (context, snapshot) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            itemCount: OrdersScreen.orders.length,
            itemBuilder: (context, index) {
              final order = OrdersScreen.orders[index];
              return GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChatScreen(order: order)),
                  );
                  if (result == true) setState(() {});
                },
                child: OrderCard(
                  order: order,
                  cardHeight: cardHeight,
                  imageSize: imageSize,
                ),
              );
            },
          );
        },
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
                Flexible(
                  child: Text(
                    '${order.userName} - بائع',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontFamily: 'Cairo',
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
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
