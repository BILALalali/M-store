import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/support_conversation.dart';
import '../../../core/services/support_chat_service.dart';
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
  List<SupportConversation> _conversations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, open, closed
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _loadStats();
    _startListening();
  }

  @override
  void dispose() {
    _chatService.stopListening();
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

      final conversations = await _chatService.getConversations();
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
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

  Future<void> _loadStats() async {
    try {
      final stats = await _chatService.getChatStats();
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      print('خطأ في جلب الإحصائيات: $e');
    }
  }

  void _startListening() {
    _chatService.startListeningToConversations((conversations) {
      if (mounted) {
        setState(() {
          _conversations = conversations;
        });
      }
    });
  }

  Future<void> _testPermissions() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('جاري اختبار الصلاحيات...'),
            ],
          ),
        ),
      );

      final result = await _chatService.testAdminPermissions();

      if (mounted) {
        Navigator.of(context).pop(); // إغلاق dialog الانتظار

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(result ? 'الصلاحيات صحيحة' : 'مشكلة في الصلاحيات'),
            content: Text(
              result
                  ? 'المدير موجود في جدول admin_users ويمكنه الوصول للبيانات'
                  : 'المدير غير موجود في جدول admin_users أو هناك مشكلة في الصلاحيات',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('موافق'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // إغلاق dialog الانتظار

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('خطأ في اختبار الصلاحيات'),
            content: Text('حدث خطأ أثناء اختبار الصلاحيات: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('موافق'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _testConnection() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('جاري اختبار الاتصال...'),
            ],
          ),
        ),
      );

      final result = await _chatService.testDatabaseConnection();

      if (mounted) {
        Navigator.of(context).pop(); // إغلاق dialog الانتظار

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(result ? 'نجح الاختبار' : 'فشل الاختبار'),
            content: Text(
              result
                  ? 'تم الاتصال بقاعدة البيانات بنجاح'
                  : 'فشل في الاتصال بقاعدة البيانات. تحقق من السجلات للحصول على التفاصيل.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('موافق'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // إغلاق dialog الانتظار

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('خطأ في الاختبار'),
            content: Text('حدث خطأ أثناء اختبار الاتصال: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('موافق'),
              ),
            ],
          ),
        );
      }
    }
  }

  List<SupportConversation> get _filteredConversations {
    var filtered = _conversations;

    // تصفية حسب الحالة
    if (_statusFilter != 'all') {
      final isOpen = _statusFilter == 'open';
      filtered = filtered.where((conv) => conv.isOpen == isOpen).toList();
    }

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

          // الإحصائيات
          _buildStatsBar(),

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
              _buildFilterChip('مفتوحة', 'open'),
              const SizedBox(width: 8),
              _buildFilterChip('مغلقة', 'closed'),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.security, color: AppColors.info),
                onPressed: _testPermissions,
                tooltip: 'اختبار الصلاحيات',
              ),
              IconButton(
                icon: Icon(Icons.bug_report, color: AppColors.warning),
                onPressed: _testConnection,
                tooltip: 'اختبار الاتصال',
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: AppColors.primary),
                onPressed: _loadConversations,
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
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.text,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: AppColors.secondary)),
      ),
      child: Row(
        children: [
          _buildStatItem(
            'إجمالي المحادثات',
            '${_stats['total_conversations'] ?? 0}',
          ),
          const SizedBox(width: 24),
          _buildStatItem(
            'مفتوحة',
            '${_stats['open_conversations'] ?? 0}',
            AppColors.success,
          ),
          const SizedBox(width: 24),
          _buildStatItem(
            'مغلقة',
            '${_stats['closed_conversations'] ?? 0}',
            AppColors.error,
          ),
          const SizedBox(width: 24),
          _buildStatItem(
            'الرسائل',
            '${_stats['total_messages'] ?? 0}',
            AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, [Color? color]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.text,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.text.withValues(alpha: 0.7),
          ),
        ),
      ],
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
            'لا توجد محادثات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.text.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر محادثات فريق الدعم هنا عندما يبدأ المستخدمون المحادثة',
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: conversation.isOpen ? AppColors.success : AppColors.error,
          width: 1,
        ),
      ),
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
                          child: Text(
                            conversation.userName ?? 'مستخدم',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: conversation.isOpen
                                ? AppColors.success
                                : AppColors.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            conversation.isOpen ? 'مفتوحة' : 'مغلقة',
                            style: const TextStyle(
                              color: Colors.white,
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
                          color: AppColors.text.withValues(alpha: 0.8),
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
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${conversation.unreadCount}',
                              style: const TextStyle(
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

  void _openConversation(SupportConversation conversation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SupportChatScreen(conversation: conversation),
      ),
    );
  }
}
