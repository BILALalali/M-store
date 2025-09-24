import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/support_conversation.dart';
import '../../../core/models/support_message.dart';
import '../../../core/services/support_chat_service.dart';
import '../../../core/services/notification_service.dart';

class SupportChatScreen extends StatefulWidget {
  final SupportConversation conversation;

  const SupportChatScreen({super.key, required this.conversation});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final SupportChatService _chatService = SupportChatService();
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<SupportMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _hasUnreadMessages = false;
  SupportConversation? _currentConversation;

  @override
  void initState() {
    super.initState();
    _currentConversation = widget.conversation;
    _loadMessages();
    _startListening();

    // تعيين الرسائل كمقروءة عند فتح المحادثة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  @override
  void dispose() {
    _chatService.stopListening();
    _notificationService.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messages = await _chatService.getMessages(widget.conversation.id);

      print('=== جلب الرسائل ===');
      print('عدد الرسائل المستلمة: ${messages.length}');
      for (int i = 0; i < messages.length; i++) {
        final msg = messages[i];
        print(
          '$i. رسالة: "${msg.message}" - الوقت: ${msg.createdAt} - المرسل: ${msg.senderType}',
        );
      }
      print('==================');

      setState(() {
        _messages = messages; // لا نرتب هنا، سنرتب في _buildMessagesList
        _isLoading = false;
        _updateUnreadStatus();
      });

      // التمرير إلى آخر رسالة
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في جلب الرسائل: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _startListening() {
    _chatService.startListeningToMessages(widget.conversation.id, (
      messages,
    ) async {
      if (mounted) {
        print('=== تحديث مباشر للرسائل ===');
        print('عدد الرسائل المستلمة: ${messages.length}');
        for (int i = 0; i < messages.length; i++) {
          final msg = messages[i];
          print(
            '$i. رسالة: "${msg.message}" - الوقت: ${msg.createdAt} - المرسل: ${msg.senderType}',
          );
        }
        print('========================');

        setState(() {
          _messages = messages; // لا نرتب هنا، سنرتب في _buildMessagesList
          _updateUnreadStatus();
        });

        // تحديث الإشعارات عند وصول رسالة جديدة
        await _notificationService.refreshNotifications();

        // التمرير إلى آخر رسالة عند وصول رسالة جديدة
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // الرسائل مرتبة من الأقدم للأحدث، آخر رسالة هي في الأسفل
      _scrollController.animateTo(
        _scrollController
            .position
            .maxScrollExtent, // التمرير إلى الأسفل لعرض آخر رسالة
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // تحديث حالة الرسائل غير المقروءة
  void _updateUnreadStatus() {
    if (_messages.isEmpty) {
      _hasUnreadMessages = false;
      return;
    }

    // البحث عن آخر رسالة من المستخدم
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].senderType == 'user') {
        // إذا كانت آخر رسالة من المستخدم، فهناك رسائل غير مقروءة
        _hasUnreadMessages = true;
        return;
      }
    }

    // إذا لم توجد رسائل من المستخدم، فلا توجد رسائل غير مقروءة
    _hasUnreadMessages = false;
  }

  // تعيين الرسائل كمقروءة
  Future<void> _markMessagesAsRead({bool showMessage = false}) async {
    if (_currentConversation == null) return;

    try {
      await _chatService.markMessagesAsRead(_currentConversation!.id);
      // تحديث الإشعارات
      await _notificationService.markConversationAsRead(
        _currentConversation!.id,
      );
      setState(() {
        _hasUnreadMessages = false;
      });
      if (mounted && showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تعيين الرسائل كمقروءة'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
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
      await _chatService.sendMessage(
        conversationId: widget.conversation.id,
        message: message,
      );

      _messageController.clear();

      // تعيين الرسائل كمقروءة وتحديث الإشعارات
      await _chatService.markMessagesAsRead(widget.conversation.id);
      await _notificationService.markConversationAsRead(widget.conversation.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إرسال الرسالة: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // معلومات المحادثة
          _buildConversationInfo(),

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
            _currentConversation?.userName ??
                'مستخدم ${_currentConversation?.userId ?? ''}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            _currentConversation?.userEmail ?? '',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          ),
        ],
      ),
      actions: [
        // زر المزيد
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'refresh':
                _loadMessages();
                break;
              case 'mark_read':
                _markMessagesAsRead(showMessage: true);
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
                  Text('تحديث'),
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
          ],
        ),
      ],
    );
  }

  Widget _buildConversationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.secondary)),
      ),
      child: Row(
        children: [
          // صورة المستخدم
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              _currentConversation?.userName?.isNotEmpty == true
                  ? _currentConversation!.userName![0].toUpperCase()
                  : 'م',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // معلومات المستخدم
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentConversation?.userName ??
                      'مستخدم ${_currentConversation?.userId ?? ''}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  _currentConversation?.userEmail ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.text.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          // حالة المحادثة بناءً على الرسائل غير المقروءة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _hasUnreadMessages ? AppColors.warning : AppColors.success,
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
            'ابدأ المحادثة مع المستخدم',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.text.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    print('=== عرض الرسائل ===');
    print('عدد الرسائل: ${_messages.length}');
    for (int i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      final timeStr =
          '${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}:${msg.createdAt.second.toString().padLeft(2, '0')}';
      print(
        '$i. [$timeStr] ${msg.senderType == 'admin' ? '👨‍💼' : '👤'} "${msg.message}"',
      );
    }
    print('==================');

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

  Widget _buildMessageBubble(SupportMessage message) {
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
            if (message.senderName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.senderName!,
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
                _formatMessageTime(message.createdAt),
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

  String _formatMessageTime(DateTime dateTime) {
    // تحويل التوقيت إلى المنطقة الزمنية المحلية
    final localDateTime = dateTime.toLocal();
    final now = DateTime.now().toLocal();

    final hour = localDateTime.hour.toString().padLeft(2, '0');
    final minute = localDateTime.minute.toString().padLeft(2, '0');

    // إذا كانت الرسالة من اليوم نفسه، اعرض الوقت فقط
    if (localDateTime.year == now.year &&
        localDateTime.month == now.month &&
        localDateTime.day == now.day) {
      return '$hour:$minute';
    }
    // إذا كانت الرسالة من نفس السنة، اعرض التاريخ والوقت
    else if (localDateTime.year == now.year) {
      return '${localDateTime.day.toString().padLeft(2, '0')}/${localDateTime.month.toString().padLeft(2, '0')} $hour:$minute';
    }
    // إذا كانت الرسالة من سنة مختلفة، اعرض التاريخ الكامل والوقت
    else {
      return '${localDateTime.day.toString().padLeft(2, '0')}/${localDateTime.month.toString().padLeft(2, '0')}/${localDateTime.year} $hour:$minute';
    }
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
                hintText: 'اكتب رسالتك...',
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
}
