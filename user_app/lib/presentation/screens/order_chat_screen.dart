import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_model.dart';
import '../../core/services/order_chat_service.dart';

/// أنواع الرسائل المدعومة
enum MessageType { text, image }

/// نموذج رسالة المحادثة للطلبات
class OrderChatMessage {
  final String text;
  final bool isFromUser;
  final DateTime timestamp;
  final MessageType type;
  final String? filePath;

  const OrderChatMessage({
    required this.text,
    required this.isFromUser,
    required this.timestamp,
    required this.type,
    this.filePath,
  });
}

/// شاشة محادثة الطلب
class OrderChatScreen extends StatefulWidget {
  final Order order;
  final VoidCallback? onMessagesRead;

  const OrderChatScreen({
    super.key, 
    required this.order,
    this.onMessagesRead,
  });

  @override
  State<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends State<OrderChatScreen> {
  // Controllers
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  // قائمة الرسائل
  final List<OrderChatMessage> _messages = [];
  RealtimeChannel? _channel;

  // ألوان التطبيق
  static const Color primaryColor = Color(0xFF1EC6D9);
  static const Color backgroundColor = Color(0xFFF7F7F7);

  @override
  void initState() {
    super.initState();
    _initializeWelcomeMessage();
    _bootstrapRealtime();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }

  /// تحديث حالة القراءة للرسائل من الإدارة
  void _markMessagesAsRead() async {
    final conversationId = widget.order.conversationId;
    if (conversationId != null) {
      await OrderChatService.markAdminMessagesAsRead(conversationId);
      // استدعاء callback لتحديث حالة البطاقة
      if (widget.onMessagesRead != null) {
        widget.onMessagesRead!();
      }
    }
  }

  /// إضافة رسالة الترحيب الأولية
  void _initializeWelcomeMessage() {
    String welcomeMessage;

    if (widget.order.orderType == OrderType.wholesale) {
      welcomeMessage =
          'مرحباً! تم استلام طلب الجملة الخاص بك لـ "${widget.order.productName}". سنقوم بمراجعة الطلب والرد عليك في أقرب وقت ممكن.';
    } else if (widget.order.orderType == OrderType.mobileCredit) {
      welcomeMessage =
          'مرحباً! تم استلام طلب تحويل الرصيد الخاص بك لـ "${widget.order.productName}". سنقوم بمعالجة الطلب والرد عليك في أقرب وقت ممكن.';
    } else {
      welcomeMessage =
          'مرحباً! تم تأكيد طلبك لـ "${widget.order.productName}". انتظر ردنا في أقرب وقت ممكن';
    }

    _messages.add(
      OrderChatMessage(
        text: welcomeMessage,
        isFromUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        type: MessageType.text,
      ),
    );
  }

  /// إرسال رسالة نصية
  void _sendMessage() {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    setState(() {
      _messages.add(
        OrderChatMessage(
          text: messageText,
          isFromUser: true,
          timestamp: DateTime.now(),
          type: MessageType.text,
        ),
      );
    });

    _messageController.clear();
    _scrollToBottom();
    // احفظ في Supabase إن كانت المحادثة موجودة
    final conversationId = widget.order.conversationId;
    if (conversationId != null) {
      OrderChatService.sendText(conversationId, messageText);
    }
  }

  // تم الاستغناء عن محاكاة رد الإدارة بعد ربط Supabase

  /// التمرير إلى أسفل المحادثة
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// اختيار صورة من المعرض
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        _addImageMessage(image.path, 'صورة');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في اختيار الصورة: $e');
    }
  }

  /// التقاط صورة من الكاميرا
  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        _addImageMessage(image.path, 'صورة من الكاميرا');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في التقاط الصورة: $e');
    }
  }

  /// إضافة رسالة صورة
  void _addImageMessage(String filePath, String text) {
    setState(() {
      _messages.add(
        OrderChatMessage(
          text: text,
          isFromUser: true,
          timestamp: DateTime.now(),
          type: MessageType.image,
          filePath: filePath,
        ),
      );
    });
    _scrollToBottom();

    final conversationId = widget.order.conversationId;
    if (conversationId != null) {
      OrderChatService.sendImage(conversationId, File(filePath));
    }
  }

  /// عرض رسالة خطأ
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          _buildOrderInfoCard(),
          Expanded(child: _buildMessagesList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  // تحميل الرسائل الأولى والاشتراك بالتحديثات
  Future<void> _bootstrapRealtime() async {
    final conversationId = widget.order.conversationId;
    if (conversationId == null) return;

    try {
      // تحميل الرسائل الموجودة
      final rows = await OrderChatService.fetchMessages(conversationId);
      for (final r in rows) {
        _messages.add(_mapRowToMessage(r));
      }
      setState(() {});
      _scrollToBottom();

      // الاشتراك في الرسائل الجديدة
      _channel = await OrderChatService.subscribeToMessages(conversationId, (row) {
        print('✅ رسالة جديدة وصلت في الشاشة!');
        final msg = _mapRowToMessage(row);
        setState(() {
          _messages.add(msg);
        });
        _scrollToBottom();
      });
    } catch (e) {
      print('❌ خطأ في الاشتراك بالرسائل: $e');
      // تجاهل الخطأ، المحادثة تعمل محلياً
    }
  }

  OrderChatMessage _mapRowToMessage(Map<String, dynamic> row) {
    final isFromUser = (row['sender_type'] ?? '') == 'user';
    final type = (row['type'] ?? 'text') == 'image'
        ? MessageType.image
        : MessageType.text;
    final tsString =
        (row['created_at'] ?? DateTime.now().toIso8601String()) as String;
    return OrderChatMessage(
      text: (row['message'] ?? '') as String,
      isFromUser: isFromUser,
      timestamp: DateTime.parse(tsString),
      type: type,
      filePath: row['media_url'] as String?,
    );
  }

  /// بناء شريط التطبيق
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(
              widget.order.orderType == OrderType.wholesale
                  ? Icons.local_shipping
                  : widget.order.orderType == OrderType.mobileCredit
                  ? Icons.phone_android
                  : Icons.shopping_cart,
              color: widget.order.orderType == OrderType.mobileCredit
                  ? const Color(0xFF4CAF50)
                  : primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.order.orderType == OrderType.wholesale
                            ? 'طلب جملة - ${widget.order.productName}'
                            : widget.order.orderType == OrderType.mobileCredit
                            ? 'طلب رصيد - ${widget.order.productName}'
                            : 'طلب ${widget.order.productName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.order.orderType == OrderType.wholesale) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'جملة',
                          style: TextStyle(
                            color: Color(0xFF1EC6D9),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ] else if (widget.order.orderType ==
                        OrderType.mobileCredit) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'رصيد',
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'تاريخ الطلب: ${_formatDate(widget.order.date)}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: primaryColor,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // يمكن إضافة قائمة خيارات هنا
          },
        ),
      ],
    );
  }

  /// بناء بطاقة معلومات الطلب
  Widget _buildOrderInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildProductImage(),
          const SizedBox(width: 12),
          Expanded(child: _buildProductInfo()),
        ],
      ),
    );
  }

  /// بناء صورة المنتج
  Widget _buildProductImage() {
    // التحقق من نوع الصورة (محلية أم شبكة)
    bool isLocalImage =
        widget.order.productImage.startsWith('/') ||
        widget.order.productImage.startsWith('file://');

    return GestureDetector(
      onTap: () {
        _showFullScreenImage();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: isLocalImage
            ? Image.file(
                File(widget.order.productImage),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, color: Colors.grey),
                  );
                },
              )
            : Image.network(
                widget.order.productImage,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, color: Colors.grey),
                  );
                },
              ),
      ),
    );
  }

  /// عرض الصورة بحجم كامل
  void _showFullScreenImage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageScreen(
          imagePath: widget.order.productImage,
          productName: widget.order.productName,
        ),
      ),
    );
  }

  /// بناء معلومات المنتج
  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.order.productName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        if (widget.order.orderType == OrderType.wholesale &&
            widget.order.quantity != null) ...[
          Text(
            'الكمية: ${widget.order.quantity}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1EC6D9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
        ],
        if (widget.order.orderType == OrderType.wholesale &&
            widget.order.description != null) ...[
          Text(
            'الوصف: ${widget.order.description}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
        ],
        Text(
          'الحالة: ${_getStatusText(widget.order.status)}',
          style: TextStyle(
            fontSize: 12,
            color: _getStatusColor(widget.order.status),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// بناء قائمة الرسائل
  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  /// بناء فقاعة الرسالة
  Widget _buildMessageBubble(OrderChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isFromUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isFromUser) ...[
            _buildAvatar(false),
            const SizedBox(width: 8),
          ],
          Flexible(child: _buildMessageContent(message)),
          if (message.isFromUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(true),
          ],
        ],
      ),
    );
  }

  /// بناء الصورة الرمزية
  Widget _buildAvatar(bool isUser) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser ? primaryColor : primaryColor,
      child: Icon(
        isUser ? Icons.person : Icons.shopping_cart,
        size: 16,
        color: Colors.white,
      ),
    );
  }

  /// بناء محتوى الرسالة
  Widget _buildMessageContent(OrderChatMessage message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: message.isFromUser ? primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomLeft: message.isFromUser
              ? const Radius.circular(20)
              : const Radius.circular(4),
          bottomRight: message.isFromUser
              ? const Radius.circular(4)
              : const Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMessageText(message),
          const SizedBox(height: 4),
          _buildMessageTime(message.timestamp),
        ],
      ),
    );
  }

  /// بناء نص الرسالة
  Widget _buildMessageText(OrderChatMessage message) {
    if (message.type == MessageType.text) {
      return Text(
        message.text,
        style: TextStyle(
          color: message.isFromUser ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
      );
    } else if (message.type == MessageType.image && message.filePath != null) {
      final path = message.filePath!;
      final isRemote = path.startsWith('http');
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: isRemote
            ? Image.network(path, width: 220, height: 220, fit: BoxFit.cover)
            : Image.file(
                File(path),
                width: 220,
                height: 220,
                fit: BoxFit.cover,
              ),
      );
    }
    return const SizedBox.shrink();
  }

  /// بناء وقت الرسالة
  Widget _buildMessageTime(DateTime timestamp) {
    return Text(
      _formatTime(timestamp),
      style: const TextStyle(color: Colors.grey, fontSize: 12),
    );
  }

  /// بناء حقل إدخال الرسالة
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAttachmentButton(),
          const SizedBox(width: 12),
          _buildTextField(),
          const SizedBox(width: 12),
          _buildSendButton(),
        ],
      ),
    );
  }

  /// بناء زر المرفقات
  Widget _buildAttachmentButton() {
    return GestureDetector(
      onTap: _showAttachmentOptions,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Icon(Icons.attach_file, color: Colors.grey, size: 24),
      ),
    );
  }

  /// بناء حقل النص
  Widget _buildTextField() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(25),
        ),
        child: TextField(
          controller: _messageController,
          decoration: const InputDecoration(
            hintText: 'اكتب رسالتك هنا...',
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          maxLines: null,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _sendMessage(),
        ),
      ),
    );
  }

  /// بناء زر الإرسال
  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _sendMessage,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Icon(Icons.send, color: Colors.white, size: 24),
      ),
    );
  }

  /// عرض خيارات المرفقات
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('اختيار من المعرض'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('التقاط صورة'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// تنسيق الوقت
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now().toLocal();
    final localTimestamp = timestamp.toLocal();

    final hour = localTimestamp.hour.toString().padLeft(2, '0');
    final minute = localTimestamp.minute.toString().padLeft(2, '0');

    // إذا كانت الرسالة من اليوم نفسه، اعرض الوقت فقط
    if (localTimestamp.year == now.year &&
        localTimestamp.month == now.month &&
        localTimestamp.day == now.day) {
      return '$hour:$minute';
    }
    // إذا كانت الرسالة من نفس السنة، اعرض التاريخ والوقت
    else if (localTimestamp.year == now.year) {
      return '${localTimestamp.day.toString().padLeft(2, '0')}/${localTimestamp.month.toString().padLeft(2, '0')} $hour:$minute';
    }
    // إذا كانت الرسالة من سنة مختلفة، اعرض التاريخ الكامل والوقت
    else {
      return '${localTimestamp.day.toString().padLeft(2, '0')}/${localTimestamp.month.toString().padLeft(2, '0')}/${localTimestamp.year} $hour:$minute';
    }
  }

  /// تنسيق التاريخ
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// الحصول على نص الحالة
  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'قيد المراجعة';
      case OrderStatus.confirmed:
        return 'تم التأكيد';
      case OrderStatus.cancelled:
        return 'تم الإلغاء';
    }
  }

  /// الحصول على لون الحالة
  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}

/// شاشة عرض الصورة بحجم كامل
class FullScreenImageScreen extends StatelessWidget {
  final String imagePath;
  final String productName;

  const FullScreenImageScreen({
    super.key,
    required this.imagePath,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    // التحقق من نوع الصورة (محلية أم شبكة)
    bool isLocalImage =
        imagePath.startsWith('/') || imagePath.startsWith('file://');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'صورة المنتج: $productName',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Cairo',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: isLocalImage
              ? Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'خطأ في تحميل الصورة',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : Image.network(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'خطأ في تحميل الصورة',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Cairo',
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
    );
  }
}
