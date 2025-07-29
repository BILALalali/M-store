enum OrderStatus { pending, confirmed, cancelled }

class Order {
  final String productName;
  final String productImage;
  final String productId;
  final String productUrl;
  final DateTime date;
  final OrderStatus status;
  final String userName;
  final bool hasUnreadMessages;

  Order({
    required this.productName,
    required this.productImage,
    required this.productId,
    required this.productUrl,
    required this.date,
    required this.status,
    required this.userName,
    this.hasUnreadMessages = false,
  });
}
