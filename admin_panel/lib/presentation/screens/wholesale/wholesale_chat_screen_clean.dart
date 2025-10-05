import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/wholesale_request.dart';
import '../../../core/models/wholesale_message.dart';
import '../../../core/services/wholesale_service.dart';

class WholesaleChatScreen extends StatefulWidget {
  final WholesaleRequest request;

  const WholesaleChatScreen({super.key, required this.request});

  @override
  State<WholesaleChatScreen> createState() => _WholesaleChatScreenState();
}

class _WholesaleChatScreenState extends State<WholesaleChatScreen> {
  final WholesaleService _wholesaleService = WholesaleService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<WholesaleMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _hasUnreadMessages = false;
  bool _isConnected = false;
  WholesaleRequest? _currentRequest;

  @override
  void initState() {
    super.initState();
    _currentRequest = widget.request;
    _loadMessages();
    _startListening();

    // تحديث تلقائي للرسائل عند فتح المحادثة
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('📖 ==== تحديث الرسائل عند فتح المحادثة ====');
      print('📋 معرف المحادثة: ${_currentRequest?.id}');

      // تأخير للتأكد من تحميل الرسائل
      await Future.delayed(const Duration(milliseconds: 1500));

      try {
        // تحديث الرسائل كمقروءة
        await _wholesaleService.markWholesaleMessagesAsRead(
          _currentRequest!.id,
        );

        // إعادة تحميل الرسائل
        await _loadMessages();

        print('✅ تم تحديث الرسائل بنجاح');
      } catch (e) {
        print('❌ خطأ في تحديث الرسائل: $e');
      }

      print('📖 ==== انتهاء التحديث ====');
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (_currentRequest == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final messages = await _wholesaleService.getWholesaleMessages(
        _currentRequest!.id,
      );

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      _updateUnreadStatus();
      _scrollToBottom();
    } catch (e) {
      print('❌ خطأ في تحميل الرسائل: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startListening() {
    // بدء الاستماع للرسائل
    _wholesaleService.startListeningToWholesaleMessages(_currentRequest!.id, (
      messages,
    ) {
      if (mounted) {
        setState(() {
          _messages = messages;
          _isConnected = true;
        });
        _updateUnreadStatus();
        _scrollToBottom();
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

    // البحث عن رسائل غير مقروءة من المستخدمين فقط
    int unreadCount = 0;
    for (var message in _messages) {
      if (message.senderType == 'user' && !message.isRead) {
        unreadCount++;
      }
    }

    bool newUnreadStatus = unreadCount > 0;

    // تحديث الواجهة فقط إذا تغيرت الحالة
    if (mounted && _hasUnreadMessages != newUnreadStatus) {
      setState(() {
        _hasUnreadMessages = newUnreadStatus;
      });
      print(
        '📊 تم تحديث حالة الرسائل غير المقروءة: $_hasUnreadMessages (عدد الرسائل: $unreadCount)',
      );
    } else {
      print('📊 عدد الرسائل غير المقروءة: $unreadCount (الحالة لم تتغير)');
    }
  }

  int _getUnreadCount() {
    if (_messages.isEmpty) return 0;

    int unreadCount = 0;
    for (var message in _messages) {
      if (message.senderType == 'user' && !message.isRead) {
        unreadCount++;
      }
    }

    return unreadCount;
  }

  Future<void> _markMessagesAsRead({bool showMessage = false}) async {
    if (_currentRequest == null) return;

    try {
      print('📖 ==== تحديث الرسائل كمقروءة ====');
      print('📋 معرف المحادثة: ${_currentRequest!.id}');

      // تحديث الرسائل في قاعدة البيانات
      await _wholesaleService.markWholesaleMessagesAsRead(_currentRequest!.id);

      // إعادة تحميل الرسائل
      final updatedMessages = await _wholesaleService.getWholesaleMessages(
        _currentRequest!.id,
      );

      // تحديث الواجهة
      setState(() {
        _messages = updatedMessages;
        _hasUnreadMessages = false;
      });

      if (mounted && showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث الرسائل كمقروءة'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }

      print('✅ تم تحديث الرسائل بنجاح');
    } catch (e) {
      print('❌ خطأ في تحديث الرسائل: $e');
      if (mounted && showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث الرسائل: $e'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      setState(() {
        _isSending = true;
      });

      await _wholesaleService.sendWholesaleMessage(
        requestId: _currentRequest!.id,
        message: messageText,
      );

      // إعادة تحميل الرسائل
      await _loadMessages();
    } catch (e) {
      print('❌ خطأ في إرسال الرسالة: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إرسال الرسالة: $e'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _updateRequestStatus(String status) async {
    if (_currentRequest == null) return;

    try {
      await _wholesaleService.updateWholesaleRequestStatus(
        _currentRequest!.id,
        status,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث حالة الطلب إلى: $status'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ خطأ في تحديث حالة الطلب: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث حالة الطلب: $e'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // معلومات الطلب
          _buildRequestInfo(),

          // قائمة الرسائل
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد رسائل بعد',
                      style: TextStyle(fontSize: 16, color: AppColors.text),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // شريط إرسال الرسائل
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _currentRequest?.displayTitle ?? 'محادثة طلب الجملة',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
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

        // قائمة خيارات الحالة
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
              case 'status_under_review':
                _updateRequestStatus('under_review');
                break;
              case 'status_approved':
                _updateRequestStatus('approved');
                break;
              case 'status_rejected':
                _updateRequestStatus('rejected');
                break;
              case 'status_completed':
                _updateRequestStatus('completed');
                break;
              case 'status_cancelled':
                _updateRequestStatus('cancelled');
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
              value: 'status_under_review',
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColors.info),
                  SizedBox(width: 8),
                  Text('قيد الدراسة'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'status_approved',
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  SizedBox(width: 8),
                  Text('موافق عليه'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'status_rejected',
              child: Row(
                children: [
                  Icon(Icons.cancel, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('مرفوض'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'status_completed',
              child: Row(
                children: [
                  Icon(Icons.done_all, color: AppColors.success),
                  SizedBox(width: 8),
                  Text('مكتمل'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'status_cancelled',
              child: Row(
                children: [
                  Icon(Icons.close, color: AppColors.warning),
                  SizedBox(width: 8),
                  Text('ملغي'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequestInfo() {
    if (_currentRequest == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: AppColors.text.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // معلومات الطلب الأساسية
          Row(
            children: [
              // أيقونة المنتج
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.business_center,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              // تفاصيل الطلب
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentRequest!.displayTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentRequest!.displayUserName,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.text.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // حالة الرسائل مع العدد
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _hasUnreadMessages ? 'رسائل جديدة' : 'مقروءة',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_hasUnreadMessages) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_getUnreadCount()}',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // تفاصيل طلب الجملة
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.text.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.inventory,
                      size: 16,
                      color: AppColors.text.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'الكمية: ${_currentRequest!.quantity} قطعة',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.text.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppColors.text.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'تاريخ الطلب: ${_formatDate(_currentRequest!.createdAt)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.text.withValues(alpha: 0.8),
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

  Widget _buildMessageBubble(WholesaleMessage message) {
    final isFromUser = message.senderType == 'user';
    final isUnread = !message.isRead && isFromUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isFromUser
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (isFromUser) ...[
            // صورة المستخدم
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Icon(Icons.person, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
          ],

          // فقاعة الرسالة
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isFromUser
                    ? (isUnread
                          ? AppColors.warning.withValues(alpha: 0.1)
                          : AppColors.background)
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isFromUser ? const Radius.circular(4) : null,
                  bottomRight: !isFromUser ? const Radius.circular(4) : null,
                ),
                border: isUnread
                    ? Border.all(color: AppColors.warning, width: 2)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      fontSize: 16,
                      color: isFromUser ? AppColors.text : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isFromUser
                              ? AppColors.text.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.mark_email_unread,
                          size: 12,
                          color: AppColors.warning,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (!isFromUser) ...[
            const SizedBox(width: 8),
            // صورة المدير
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: Icon(
                Icons.admin_panel_settings,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(
            color: AppColors.text.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'اكتب رسالتك هنا...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              onPressed: _isSending ? null : _sendMessage,
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
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
