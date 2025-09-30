import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/order_thread.dart';
import '../../../core/models/order_message.dart';
import '../../../core/services/order_service.dart';

class OrderChatScreen extends StatefulWidget {
  final OrderThread order;

  const OrderChatScreen({super.key, required this.order});

  @override
  State<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends State<OrderChatScreen> {
  final OrderService _orderService = OrderService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<OrderMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _hasUnreadMessages = false;
  bool _isConnected = false;
  OrderThread? _currentOrder;

  @override
  void initState() {
    super.initState();
    print('🎬 ==== تهيئة شاشة محادثة الطلب ====');
    print('📋 معلومات الطلب:');
    print('   - ID: ${widget.order.id}');
    print('   - Title: ${widget.order.title}');
    print('   - User ID: ${widget.order.userId}');
    print('   - User Name: ${widget.order.userName}');
    print('   - Status: ${widget.order.status}');
    print('   - Order Type: ${widget.order.orderType}');

    _currentOrder = widget.order;
    _loadMessages();
    _startListening();

    // تعيين الرسائل كمقروءة عند فتح المحادثة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  @override
  void dispose() {
    _orderService.stopListening();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🚀 ==== بدء تحميل الرسائل في واجهة المشرف ====');
      print('📋 معرف الطلب: ${widget.order.id}');
      print('📋 عنوان الطلب: ${widget.order.title}');
      print('👤 معرف المستخدم: ${widget.order.userId}');
      print('👤 اسم المستخدم: ${widget.order.userName}');

      final messages = await _orderService.getOrderMessages(widget.order.id);

      print('=== نتيجة جلب رسائل الطلب ===');
      print('عدد الرسائل المستلمة: ${messages.length}');

      if (messages.isNotEmpty) {
        print('📋 تفاصيل الرسائل:');
        for (int i = 0; i < messages.length; i++) {
          final msg = messages[i];
          print(
            '   ${i + 1}. ${msg.senderType}: ${msg.message} (${msg.detailedTime})',
          );
        }
      } else {
        print('⚠️ لم يتم العثور على أي رسائل');
      }

      setState(() {
        _messages = messages;
        _isLoading = false;
        _updateUnreadStatus();
      });

      // التمرير إلى آخر رسالة
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      print('✅ انتهاء تحميل الرسائل في واجهة المشرف');
    } catch (e) {
      print('❌ خطأ في تحميل الرسائل: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في جلب رسائل الطلب: $e'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _startListening() {
    setState(() {
      _isConnected = true;
    });

    _orderService.startListeningToOrderMessages(widget.order.id, (messages) {
      if (mounted) {
        print('=== تحديث مباشر لرسائل الطلب ===');
        print('عدد الرسائل المستلمة: ${messages.length}');

        // التحقق من وجود رسائل جديدة
        final oldCount = _messages.length;
        final newCount = messages.length;
        final hasNewMessages = newCount > oldCount;

        setState(() {
          _messages = messages;
          _updateUnreadStatus();
          _isConnected = true;
        });

        // التمرير إلى آخر رسالة عند وصول رسالة جديدة فقط
        if (hasNewMessages) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    });

    // مراقبة حالة الاتصال
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_isConnected) {
        setState(() {
          _isConnected = false;
        });
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _updateUnreadStatus() {
    if (_messages.isEmpty) {
      _hasUnreadMessages = false;
      return;
    }

    // البحث عن آخر رسالة من المستخدم
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].senderType == 'user') {
        _hasUnreadMessages = true;
        return;
      }
    }

    _hasUnreadMessages = false;
  }

  Future<void> _markMessagesAsRead({bool showMessage = false}) async {
    if (_currentOrder == null) return;

    try {
      print('🔄 بدء تحديث الرسائل كمقروءة من شاشة المحادثة...');

      final updatedCount = await _orderService.markOrderMessagesAsRead(
        _currentOrder!.id,
      );

      setState(() {
        _hasUnreadMessages = false;
      });

      if (mounted && showMessage) {
        final message = updatedCount > 0
            ? 'تم تعيين $updatedCount رسالة كمقروءة'
            : 'لا توجد رسائل غير مقروءة';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: updatedCount > 0
                ? AppColors.success
                : AppColors.info,
          ),
        );
      }

      print('✅ تم تحديث $updatedCount رسالة في شاشة المحادثة');
    } catch (e) {
      print('❌ خطأ في تحديث الرسائل من شاشة المحادثة: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تعيين الرسائل كمقروءة: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final sentMessage = await _orderService.sendOrderMessage(
        orderId: widget.order.id,
        message: message,
      );

      _messageController.clear();

      // إضافة الرسالة للقائمة فوراً لتحسين تجربة المستخدم
      if (sentMessage != null && mounted) {
        setState(() {
          _messages.add(sentMessage);
        });

        // التمرير إلى آخر رسالة
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }

      // تعيين الرسائل كمقروءة بعد الإرسال
      final updatedAfterSend = await _orderService.markOrderMessagesAsRead(
        widget.order.id,
      );
      print('📖 تم تحديث $updatedAfterSend رسالة بعد إرسال الرد');

      // إظهار رسالة نجاح
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال الرسالة بنجاح'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إرسال الرسالة: $e'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    try {
      final success = await _orderService.updateOrderStatus(
        widget.order.id,
        newStatus,
      );
      if (success && mounted) {
        setState(() {
          _currentOrder = _currentOrder?.copyWith(status: newStatus);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحديث حالة الطلب إلى ${_getStatusDisplayName(newStatus)}',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث حالة الطلب: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'processing':
        return 'قيد المعالجة';
      case 'completed':
        return 'مكتمل';
      case 'cancelled':
        return 'ملغى';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // معلومات الطلب
          _buildOrderInfo(),

          // قائمة الرسائل
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? _buildEmptyState()
                : _buildMessagesList(),
          ),

          // شريط إرسال الرسائل
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentOrder?.displayTitle ?? 'طلب',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            _currentOrder?.displayUserName ?? '',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          ),
        ],
      ),
      actions: [
        // مؤشر حالة الاتصال
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _isConnected ? AppColors.success : AppColors.warning,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),

        // زر تحديث حالة الطلب
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'refresh':
                _loadMessages();
                _startListening(); // إعادة تفعيل الاستماع
                break;
              case 'mark_read':
                _markMessagesAsRead(showMessage: true);
                break;
              case 'status_processing':
                _updateOrderStatus('processing');
                break;
              case 'status_completed':
                _updateOrderStatus('completed');
                break;
              case 'status_cancelled':
                _updateOrderStatus('cancelled');
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('تحديث المحادثة'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'mark_read',
              child: Row(
                children: [
                  Icon(Icons.mark_email_read),
                  SizedBox(width: 8),
                  Text('تعيين كمقروء'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'status_processing',
              child: Row(
                children: [
                  Icon(Icons.hourglass_bottom, color: AppColors.info),
                  SizedBox(width: 8),
                  Text('قيد المعالجة'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'status_completed',
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  SizedBox(width: 8),
                  Text('مكتمل'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'status_cancelled',
              child: Row(
                children: [
                  Icon(Icons.cancel, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('إلغاء'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.secondary)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // معلومات أساسية
          Row(
            children: [
              // صورة المستخدم
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  _currentOrder?.userName?.isNotEmpty == true
                      ? _currentOrder!.userName![0].toUpperCase()
                      : 'م',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // معلومات المستخدم والطلب
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentOrder?.displayUserName ?? 'مستخدم',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      'رقم الطلب: ${_currentOrder?.id.substring(0, 8) ?? ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.text.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // حالة الطلب
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(_currentOrder?.status ?? 'pending'),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _currentOrder?.displayStatus ?? 'قيد المراجعة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // حالة الرسائل
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _hasUnreadMessages
                      ? AppColors.warning
                      : AppColors.success,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _hasUnreadMessages ? 'رسائل جديدة' : 'مقروءة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // تفاصيل الطلب
          if (_currentOrder?.productNames != null &&
              _currentOrder!.productNames!.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.shopping_cart,
                  size: 16,
                  color: AppColors.text.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'المنتجات: ${_currentOrder!.productNames}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.text.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          if (_currentOrder?.summary != null &&
              _currentOrder!.summary!.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.description,
                  size: 16,
                  color: AppColors.text.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentOrder!.summary!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.text.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // نوع الطلب والوقت
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTypeColor(
                    _currentOrder?.orderType ?? 'retail',
                  ).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getTypeColor(_currentOrder?.orderType ?? 'retail'),
                    width: 1,
                  ),
                ),
                child: Text(
                  _currentOrder?.displayOrderType ?? 'تجزئة',
                  style: TextStyle(
                    color: _getTypeColor(_currentOrder?.orderType ?? 'retail'),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const Spacer(),

              Text(
                'تاريخ الإنشاء: ${_formatDateTime(_currentOrder?.createdAt ?? DateTime.now())}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.text.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppColors.text.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد رسائل بعد',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.text.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ المحادثة مع المستخدم حول هذا الطلب',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.text.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          if (!_isConnected) ...[
            ElevatedButton.icon(
              onPressed: () {
                _loadMessages();
                _startListening();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة الاتصال'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

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

  Widget _buildMessageBubble(OrderMessage message) {
    final isFromAdmin = message.isFromAdmin;

    return Align(
      alignment: isFromAdmin ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isFromAdmin
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // اسم المرسل
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                message.displaySenderName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text.withValues(alpha: 0.6),
                ),
              ),
            ),

            // فقاعة الرسالة
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFromAdmin
                    ? AppColors.primary
                    : AppColors.cardBackground,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isFromAdmin
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isFromAdmin
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                border: Border.all(
                  color: isFromAdmin ? AppColors.primary : AppColors.secondary,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // محتوى الرسالة
                  if (message.isTextMessage)
                    Text(
                      message.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: isFromAdmin ? Colors.white : AppColors.text,
                      ),
                    )
                  else if (message.isImageMessage && message.mediaUrl != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            message.mediaUrl!,
                            width: 200,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 150,
                                color: AppColors.secondary,
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: AppColors.text.withValues(alpha: 0.5),
                                ),
                              );
                            },
                          ),
                        ),
                        if (message.message.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            message.message,
                            style: TextStyle(
                              fontSize: 14,
                              color: isFromAdmin
                                  ? Colors.white
                                  : AppColors.text,
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),

            // وقت الرسالة
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                message.detailedTime,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.text.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.secondary)),
      ),
      child: Row(
        children: [
          // حقل النص
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'اكتب رسالتك للمستخدم...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.secondary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textDirection: TextDirection.rtl,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),

          const SizedBox(width: 12),

          // زر الإرسال
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _isSending ? null : _sendMessage,
              tooltip: 'إرسال',
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'processing':
        return AppColors.info;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'retail':
        return AppColors.primary;
      case 'delivery':
        return AppColors.info;
      case 'mobileCredit':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final localDateTime = dateTime.toLocal();
    final day = localDateTime.day.toString().padLeft(2, '0');
    final month = localDateTime.month.toString().padLeft(2, '0');
    final year = localDateTime.year;
    final hour = localDateTime.hour.toString().padLeft(2, '0');
    final minute = localDateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}
