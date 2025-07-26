enum OrderStatus { pending, confirmed, cancelled }

class Order {
  final String productName;
  final String productImage;
  final DateTime date;
  final OrderStatus status;
  final String userName;

  Order({
    required this.productName,
    required this.productImage,
    required this.date,
    required this.status,
    required this.userName,
  });
}
