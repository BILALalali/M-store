enum OrderStatus { pending, confirmed, cancelled }

enum OrderType { retail, wholesale, delivery }

class Order {
  final String productName;
  final String productImage;
  final String productId;
  final String productUrl;
  final DateTime date;
  final OrderStatus status;
  final String userName;
  final bool hasUnreadMessages;
  final OrderType orderType;
  final String? description; // للطلبات الجملة
  final int? quantity; // للطلبات الجملة

  Order({
    required this.productName,
    required this.productImage,
    required this.productId,
    required this.productUrl,
    required this.date,
    required this.status,
    required this.userName,
    this.hasUnreadMessages = false,
    this.orderType = OrderType.retail,
    this.description,
    this.quantity,
  });
}
