import 'package:flutter/material.dart';
import 'order_model.dart';

class ChatScreen extends StatefulWidget {
  final Order order;
  const ChatScreen({super.key, required this.order});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const Color primaryColor = Color(0xFF1EC6D9);
  static const Color backgroundColor = Color(0xFFF7F7F7);
  final TextEditingController _controller = TextEditingController();
  final List<String> messages = [
    'مرحباً، تم استلام طلبك وسيتم التواصل معك قريباً.',
    'شكرًا لكم، بانتظار التأكيد.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.order.productName,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              widget.order.userName,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(widget.order.status),
                  color: _getStatusColor(widget.order.status),
                ),
                const SizedBox(width: 4),
                Text(
                  _getStatusText(widget.order.status),
                  style: TextStyle(
                    color: _getStatusColor(widget.order.status),
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final isUser = index % 2 == 1;
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? primaryColor.withOpacity(0.15)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      messages[index],
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'اكتب رسالة...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: primaryColor),
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                      setState(() {
                        messages.add(_controller.text.trim());
                        _controller.clear();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
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

  IconData _getStatusIcon(OrderStatus status) {
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

  String _getStatusText(OrderStatus status) {
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
}
