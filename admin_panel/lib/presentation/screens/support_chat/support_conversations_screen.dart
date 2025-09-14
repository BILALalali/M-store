import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/support_conversation.dart';
import '../../../core/services/support_chat_service.dart';
import '../../../core/services/notification_service.dart';
import 'support_chat_screen.dart';

class SupportConversationsScreen extends StatefulWidget {
  const SupportConversationsScreen({super.key});

  @override
  State<SupportConversationsScreen> createState() =>
      _SupportConversationsScreenState();
}

class _SupportConversationsScreenState
    extends State<SupportConversationsScreen> {
  final SupportChatService _chatService = SupportChatService();
  final NotificationService _notificationService = NotificationService();
  List<SupportConversation> _conversations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, open, closed

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _startListening();
  }

  @override
  void dispose() {
    _chatService.stopListening();
    _notificationService.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // اختبار الاتصال أولاً
      final connectionTest = await _chatService.testDatabaseConnection();
      print('نتيجة اختبار الاتصال: $connectionTest');

      // اختبار الرسائل غير المقروءة
      await _chatService.testUnreadMessages();

      // جلب المحادثات حسب التصفية المحددة
      List<SupportConversation> conversations;
      if (_statusFilter == 'unread') {
        conversations = await _chatService.getUnreadConversations();
        print('📊 تم جلب ${conversations.length} محادثة غير مقروءة');
      } else {
        conversations = await _chatService.getConversations();
        print('📊 تم جلب ${conversations.length} محادثة');
      }

      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });

      // تحديث الإشعارات بعد جلب المحادثات
      await _notificationService.refreshNotifications();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في جلب المحادثات: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _startListening() {
    _chatService.startListeningToConversations((conversations) async {
      if (mounted) {
        setState(() {
          _conversations = conversations;
        });
        // تحديث الإشعارات عند تحديث المحادثات
        await _notificationService.refreshNotifications();
      }
    });

    // الاستماع لتحديثات الإشعارات لتحديث الإحصائيات
    _notificationService.addListener(() {
      if (mounted) {
        setState(() {
          // تحديث الواجهة عند تغيير الإشعارات
        });
      }
    });
  }

  List<SupportConversation> get _filteredConversations {
    var filtered = _conversations;

    // تصفية حسب البحث
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((conv) {
        final userName = conv.userName?.toLowerCase() ?? '';
        final userEmail = conv.userEmail?.toLowerCase() ?? '';
        final lastMessage = conv.lastMessage?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();

        return userName.contains(query) ||
            userEmail.contains(query) ||
            lastMessage.contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // شريط البحث والتصفية
          _buildSearchAndFilterBar(),

          // قائمة المحادثات
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredConversations.isEmpty
                ? _buildEmptyState()
                : _buildConversationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.secondary)),
      ),
      child: Column(
        children: [
          // شريط البحث
          TextField(
            decoration: InputDecoration(
              hintText: 'البحث في المحادثات...',
              prefixIcon: Icon(Icons.search, color: AppColors.text),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppColors.text),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.secondary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          const SizedBox(height: 12),

          // أزرار التصفية
          Row(
            children: [
              _buildFilterChip('الكل', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('غير مقروءة', 'unread'),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.refresh, color: AppColors.primary),
                onPressed: () async {
                  await _loadConversations();
                  // تحديث الإشعارات أيضاً
                  await _notificationService.refreshNotifications();
                },
                tooltip: 'تحديث',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _statusFilter = value;
        });
        // إعادة تحميل المحادثات عند تغيير التصفية
        _loadConversations();
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.text,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;

    if (_statusFilter == 'unread') {
      title = 'لا توجد محادثات غير مقروءة';
      subtitle = 'جميع المحادثات مقروءة حالياً';
      icon = Icons.mark_email_read;
    } else {
      title = 'لا توجد محادثات';
      subtitle = 'ستظهر محادثات فريق الدعم هنا عندما يبدأ المستخدمون المحادثة';
      icon = Icons.chat_bubble_outline;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.text.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.text.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.text.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredConversations.length,
      itemBuilder: (context, index) {
        final conversation = _filteredConversations[index];
        return _buildConversationCard(conversation);
      },
    );
  }

  Widget _buildConversationCard(SupportConversation conversation) {
    final hasUnreadMessages =
        conversation.hasUnreadMessages; // استخدام الحقل الجديد

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: hasUnreadMessages ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasUnreadMessages ? AppColors.warning : AppColors.success,
          width: hasUnreadMessages ? 3 : 1,
        ),
      ),
      // إضافة خلفية ملونة للمحادثات غير المقروءة
      color: hasUnreadMessages
          ? AppColors.warning.withValues(alpha: 0.05)
          : AppColors.cardBackground,
      child: InkWell(
        onTap: () => _openConversation(conversation),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // صورة المستخدم
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  conversation.userName?.isNotEmpty == true
                      ? conversation.userName![0].toUpperCase()
                      : 'م',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // معلومات المحادثة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اسم المستخدم والحالة
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              // مؤشر برتقالي للمحادثات غير المقروءة
                              if (hasUnreadMessages) ...[
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: AppColors.warning,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.warning.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  conversation.userName ??
                                      'مستخدم ${conversation.userId}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: hasUnreadMessages
                                        ? FontWeight.w900
                                        : FontWeight.bold,
                                    color: hasUnreadMessages
                                        ? AppColors.warning
                                        : AppColors.text,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // مؤشر الرسائل غير المقروءة
                        if (conversation.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${conversation.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.success,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'مقروءة',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // البريد الإلكتروني
                    if (conversation.userEmail != null)
                      Text(
                        conversation.userEmail!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.text.withValues(alpha: 0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 8),

                    // آخر رسالة
                    if (conversation.lastMessage != null)
                      Text(
                        conversation.lastMessage!,
                        style: TextStyle(
                          fontSize: 14,
                          color: hasUnreadMessages
                              ? AppColors.text
                              : AppColors.text.withValues(alpha: 0.8),
                          fontWeight: hasUnreadMessages
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 8),

                    // الوقت وعدد الرسائل غير المقروءة
                    Row(
                      children: [
                        Text(
                          _formatDateTime(
                            conversation.lastMessageAt ??
                                conversation.updatedAt,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.text.withValues(alpha: 0.5),
                          ),
                        ),
                        const Spacer(),
                        if (conversation.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  conversation.unreadCount > 99
                                      ? '99+ رسالة جديدة'
                                      : '${conversation.unreadCount} رسالة جديدة',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // سهم التنقل
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.text.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  void _openConversation(SupportConversation conversation) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SupportChatScreen(conversation: conversation),
      ),
    );

    // إعادة تحميل المحادثات عند العودة من المحادثة
    if (mounted) {
      await _loadConversations();
    }
  }
}
