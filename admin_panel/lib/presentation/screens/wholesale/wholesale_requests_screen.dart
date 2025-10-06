import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/wholesale_request.dart';
import '../../../core/services/wholesale_service.dart';
import 'wholesale_chat_screen.dart';

class WholesaleRequestsScreen extends StatefulWidget {
  const WholesaleRequestsScreen({super.key});

  @override
  State<WholesaleRequestsScreen> createState() =>
      _WholesaleRequestsScreenState();
}

class _WholesaleRequestsScreenState extends State<WholesaleRequestsScreen> {
  final WholesaleService _wholesaleService = WholesaleService();
  List<WholesaleRequest> _requests = [];
  List<WholesaleRequest> _filteredRequests = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Stream subscription للتحديثات في الوقت الفعلي
  StreamSubscription<List<WholesaleRequest>>? _requestsSubscription;

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _startListening();
  }

  @override
  void dispose() {
    _requestsSubscription?.cancel();
    _wholesaleService.stopRealtimeSubscriptions();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    print('🔄 ==== بدء تحميل طلبات الجملة ====');
    setState(() {
      _isLoading = true;
    });

    try {
      final requests = await _wholesaleService.getWholesaleRequests();

      setState(() {
        _requests = requests;
        _applyFilters();
        _isLoading = false;
      });

      print('✅ تم تحميل ${requests.length} طلب جملة بنجاح');
      print(
        '📊 عدد المحادثات الجديدة: ${requests.where((r) => r.hasUnreadMessages).length}',
      );
    } catch (e) {
      print('❌ خطأ في تحميل طلبات الجملة: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في جلب طلبات الجملة: $e'),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'إعادة المحاولة',
              textColor: Colors.white,
              onPressed: _loadRequests,
            ),
          ),
        );
      }
    }
  }

  void _startListening() {
    // بدء التحديثات في الوقت الفعلي
    _wholesaleService.startRealtimeSubscriptions();

    // الاستماع للـ stream
    _requestsSubscription = _wholesaleService.requestsStream.listen((requests) {
      if (mounted) {
        setState(() {
          _requests = requests;
          _isLoading = false;
          _applyFilters();
        });
        print(
          '🔄 تم تحديث قائمة طلبات الجملة في الشاشة: ${requests.length} طلب',
        );
      }
    });

    // الاستماع لتحديثات الرسائل لتحديث عدد الرسائل غير المقروءة
    _wholesaleService.messagesStream.listen((messages) {
      if (mounted) {
        print('📨 تم استقبال تحديث في الرسائل - إعادة تحميل الطلبات...');
        // إعادة تحميل الطلبات لتحديث عدد الرسائل غير المقروءة
        _loadRequests();
      }
    });
  }

  void _applyFilters() {
    var filtered = _requests;

    // تصفية حسب البحث
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((request) {
        final productName = request.productName.toLowerCase();
        final userName = request.userName?.toLowerCase() ?? '';
        final description = request.description.toLowerCase();
        final query = _searchQuery.toLowerCase();

        return productName.contains(query) ||
            userName.contains(query) ||
            description.contains(query);
      }).toList();
    }

    // ترتيب حسب الأولوية والتاريخ
    filtered.sort((a, b) {
      // أولاً حسب الأولوية
      int priorityComparison = a.priority.compareTo(b.priority);
      if (priorityComparison != 0) return priorityComparison;

      // ثم حسب الرسائل غير المقروءة
      if (a.hasUnreadMessages && !b.hasUnreadMessages) return -1;
      if (!a.hasUnreadMessages && b.hasUnreadMessages) return 1;

      // أخيراً حسب تاريخ التحديث
      return b.updatedAt.compareTo(a.updatedAt);
    });

    setState(() {
      _filteredRequests = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // شريط البحث والتصفية
          _buildSearchAndFilterBar(),

          // قائمة طلبات الجملة
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRequests.isEmpty
                ? _buildEmptyState()
                : _buildRequestsList(),
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
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // عنوان القسم
          Row(
            children: [
              Icon(Icons.business_center, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'طلبات الجملة',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
            ],
          ),

          const SizedBox(height: 16),

          // شريط البحث
          TextField(
            decoration: InputDecoration(
              hintText: 'البحث في طلبات الجملة...',
              prefixIcon: Icon(Icons.search, color: AppColors.text),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: AppColors.text),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _applyFilters();
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
              filled: true,
              fillColor: AppColors.background,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
          ),

          const SizedBox(height: 12),

          // أزرار التحكم
          Row(
            children: [
              const Spacer(),
              // زر التحديث
              IconButton(
                icon: Icon(Icons.refresh, color: AppColors.primary),
                onPressed: _loadRequests,
                tooltip: 'تحديث',
              ),
            ],
          ),

          const SizedBox(height: 8),

          // إحصائيات سريعة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickStat(
                'المحادثات الإجمالي',
                _requests.length,
                AppColors.primary,
              ),
              _buildQuickStat(
                'المحادثات الجديدة',
                _requests.where((r) => r.hasUnreadMessages).length,
                AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
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
            Icons.business_center_outlined,
            size: 64,
            color: AppColors.text.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد طلبات جملة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.text.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر طلبات الجملة من العملاء هنا عندما يقومون بإرسال طلبات جديدة',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.text.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          // زر إعادة التحميل
          ElevatedButton.icon(
            onPressed: _loadRequests,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة تحميل طلبات الجملة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredRequests.length,
      itemBuilder: (context, index) {
        final request = _filteredRequests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(WholesaleRequest request) {
    final hasUnreadMessages = request.hasUnreadMessages;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: hasUnreadMessages ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasUnreadMessages
              ? AppColors.warning
              : _getStatusColor(request.status),
          width: hasUnreadMessages ? 3 : 1,
        ),
      ),
      color: hasUnreadMessages
          ? AppColors.warning.withValues(alpha: 0.05)
          : AppColors.cardBackground,
      child: InkWell(
        onTap: () => _openWholesaleChat(request),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رأس الطلب
              Row(
                children: [
                  // أيقونة طلب الجملة
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.business_center,
                      color: AppColors.info,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // معلومات الطلب
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // مؤشر الرسائل غير المقروءة
                            if (hasUnreadMessages) ...[
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.warning,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                request.displayTitle,
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
                        const SizedBox(height: 4),
                        Text(
                          request.displayUserName,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.text.withValues(alpha: 0.7),
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
                      color: _getStatusColor(request.status),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      request.displayStatus,
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
              Row(
                children: [
                  // الكمية
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          request.displayQuantity,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // تاريخ الإنشاء
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(request.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // أيقونة طلب الجملة
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.business_center,
                      size: 16,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // الوصف
              Text(
                request.displayDescription,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.text.withValues(alpha: 0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // سطر المعلومات السفلي
              Row(
                children: [
                  // الوقت
                  Text(
                    _formatDateTime(request.updatedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.text.withValues(alpha: 0.5),
                    ),
                  ),

                  const Spacer(),

                  // عدد الرسائل غير المقروءة
                  if (request.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(16),
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
                            request.unreadCount > 99
                                ? '99+ رسالة'
                                : '${request.unreadCount} رسالة',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
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
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'under_review':
        return AppColors.info;
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
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

  String _formatDate(DateTime dateTime) {
    final localDateTime = dateTime.toLocal();
    final day = localDateTime.day.toString().padLeft(2, '0');
    final month = localDateTime.month.toString().padLeft(2, '0');
    final year = localDateTime.year.toString().substring(
      2,
    ); // آخر رقمين من السنة

    return '$day/$month/$year';
  }

  void _openWholesaleChat(WholesaleRequest request) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WholesaleChatScreen(request: request),
      ),
    );

    // إعادة تحميل الطلبات عند العودة لضمان تحديث حالة الرسائل
    if (mounted) {
      print('🔄 إعادة تحميل طلبات الجملة بعد العودة من المحادثة...');
      await _loadRequests();
      print('✅ تم تحديث قائمة طلبات الجملة');
    }
  }
}
