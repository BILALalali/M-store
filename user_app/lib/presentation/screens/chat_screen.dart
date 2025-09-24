import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/support_chat_service.dart';
import '../../core/services/supabase_service.dart';

/// أنواع الرسائل المدعومة
enum MessageType { text, image }

/// نموذج رسالة المحادثة العامة
class ChatMessage {
  final String text;
  final bool isFromUser;
  final DateTime timestamp;
  final MessageType type;
  final String? filePath;
  final String? imageUrl;
  final bool isUnread;

  const ChatMessage({
    required this.text,
    required this.isFromUser,
    required this.timestamp,
    required this.type,
    this.filePath,
    this.imageUrl,
    this.isUnread = false,
  });
}

/// شاشة المحادثة العامة مع فريق الدعم
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Controllers
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  // قائمة الرسائل
  final List<ChatMessage> _messages = [];
  String? _conversationId;
  StreamSubscription? _sub;
  bool _isLoading = true;

  // ألوان التطبيق
  static const Color turquoise = Color(0xFF6FD8E8);
  static const Color beige = Color(0xFFFAF6EF);

  @override
  void initState() {
    super.initState();
    _initConversation();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _initConversation() async {
    try {
      setState(() => _isLoading = true);
      if (!SupabaseService.isInitialized || SupabaseService.client == null) {
        throw Exception('Supabase غير متصل');
      }
      final convId =
          await SupportChatService.getOrCreateConversationForCurrentUser();
      _conversationId = convId;
      final rows = await SupportChatService.fetchMessages(convId);
      final uid = SupabaseService.client!.auth.currentUser?.id;
      _messages.clear();
      for (final row in rows) {
        final isFromUser =
            row['sender_type'] == 'user' && row['sender_id'] == uid;
        final type = (row['type'] == 'image')
            ? MessageType.image
            : MessageType.text;
        final isUnread = !isFromUser && (row['is_read'] == false);
        _messages.add(
          ChatMessage(
            text: row['message'] ?? '',
            isFromUser: isFromUser,
            timestamp: DateTime.parse(row['created_at']),
            type: type,
            imageUrl: row['media_url'],
            isUnread: isUnread,
          ),
        );
      }

      // تحديث حالة الرسائل كمقروءة عند فتح المحادثة
      if (_conversationId != null) {
        await SupportChatService.markMessagesAsRead(_conversationId!);
      }
      _sub = await SupportChatService.subscribeToMessages(convId, (row) {
        final uidNow = SupabaseService.client!.auth.currentUser?.id;
        final isFromUser =
            row['sender_type'] == 'user' && row['sender_id'] == uidNow;
        final type = (row['type'] == 'image')
            ? MessageType.image
            : MessageType.text;
        final isUnread = !isFromUser && (row['is_read'] == false);
        setState(() {
          _messages.add(
            ChatMessage(
              text: row['message'] ?? '',
              isFromUser: isFromUser,
              timestamp: DateTime.parse(row['created_at']),
              type: type,
              imageUrl: row['media_url'],
              isUnread: isUnread,
            ),
          );
        });
        _scrollToBottom();
      });
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('فشل تحميل المحادثة: $e');
    }
  }

  /// إرسال رسالة نصية
  void _sendMessage() {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;
    if (_conversationId == null) return;
    SupportChatService.sendTextMessage(_conversationId!, messageText);
    _messageController.clear();
    _scrollToBottom();
  }

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

      if (image != null && _conversationId != null) {
        await SupportChatService.sendImageMessage(
          _conversationId!,
          File(image.path),
        );
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

      if (image != null && _conversationId != null) {
        await SupportChatService.sendImageMessage(
          _conversationId!,
          File(image.path),
        );
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في التقاط الصورة: $e');
    }
  }

  // لم نعد نضيف محلياً، ستصل الرسالة عبر الاشتراك

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
      backgroundColor: beige,
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMessagesList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  /// بناء شريط التطبيق
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.support_agent, color: turquoise),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'فريق الدعم',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'متصل الآن',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: turquoise,
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
  Widget _buildMessageBubble(ChatMessage message) {
    const Color turquoiseDark = Color(0xFF3EC6D3);

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
          Flexible(child: _buildMessageContent(message, turquoiseDark)),
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
      backgroundColor: isUser ? const Color(0xFF3EC6D3) : turquoise,
      child: Icon(
        isUser ? Icons.person : Icons.support_agent,
        size: 16,
        color: Colors.white,
      ),
    );
  }

  /// بناء محتوى الرسالة
  Widget _buildMessageContent(ChatMessage message, Color turquoiseDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: message.isFromUser ? turquoiseDark : Colors.white,
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
        // تمييز الرسائل غير المقروءة بحدود زرقاء
        border: message.isUnread && !message.isFromUser
            ? Border.all(color: Colors.blue, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMessageText(message),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMessageTime(message.timestamp, message.isFromUser),
              if (message.isUnread && !message.isFromUser)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'جديد',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء نص الرسالة
  Widget _buildMessageText(ChatMessage message) {
    if (message.type == MessageType.text) {
      return Text(
        message.text,
        style: TextStyle(
          color: message.isFromUser ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
      );
    } else if (message.type == MessageType.image) {
      final isLocal = message.filePath != null && message.filePath!.isNotEmpty;
      final widgetImage = isLocal
          ? Image.file(
              File(message.filePath!),
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            )
          : (message.imageUrl != null
                ? Image.network(
                    message.imageUrl!,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  )
                : const SizedBox.shrink());
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: widgetImage,
      );
    }
    return const SizedBox.shrink();
  }

  /// بناء وقت الرسالة
  Widget _buildMessageTime(DateTime timestamp, bool isFromUser) {
    return Text(
      _formatTime(timestamp),
      style: TextStyle(
        color: isFromUser ? Colors.white70 : Colors.grey,
        fontSize: 12,
      ),
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
          color: turquoise,
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
}
