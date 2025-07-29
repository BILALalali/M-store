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
  // أول رسالة: تفاصيل الطلب من المستخدم
  late List<Map<String, dynamic>> messages;

  @override
  void initState() {
    super.initState();
    messages = [
      {
        'text': '''السلام عليكم، أود طلب المنتجات التالية:
المنتجات: ${widget.order.productName}''',
        'isUser': true,
        'isFirst': true,
      },
      // رسالة رد من الإدارة (محاكاة)
      {
        'text': 'مرحباً، شكراً لطلبك. سنقوم بمراجعة الطلب والرد عليك قريباً.',
        'isUser': false,
        'isAdmin': true,
      },
    ];
  }

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
              _getStatusText(widget.order.status),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: _getStatusColor(widget.order.status).withOpacity(0.8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Icon(
              _getStatusIcon(widget.order.status),
              color: _getStatusColor(widget.order.status),
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
                final isUser = messages[index]['isUser'] == true;
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
                    child: messages[index]['isFirst'] == true
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'السلام عليكم، أود طلب المنتجات التالية:',
                                style: const TextStyle(fontFamily: 'Cairo'),
                              ),
                              Text(
                                'المنتجات: ${widget.order.productName}',
                                style: const TextStyle(fontFamily: 'Cairo'),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'يرجى مراجعة تفاصيل الطلب والرد في أقرب وقت ممكن.',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            messages[index]['text'],
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
                        messages.add({
                          'text': _controller.text.trim(),
                          'isUser': true, // المستخدم هو العميل
                        });
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
