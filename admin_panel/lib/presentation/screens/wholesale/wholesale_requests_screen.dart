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
  String _selectedStatus = 'all';

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
    } catch (e) {
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

    // تصفية حسب الحالة
    if (_selectedStatus != 'all') {
      filtered = filtered
          .where((request) => request.status == _selectedStatus)
          .toList();
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
              Icon(
                Icons.business_center,
                color: AppColors.primary,
                size: 24,
              ),
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
              // زر الإحصائيات التفصيلية
              IconButton(
                icon: Icon(Icons.analytics, color: AppColors.info),
                onPressed: _showDetailedStats,
                tooltip: 'إحصائيات مفصلة',
              ),
              // زر تصدير البيانات
              IconButton(
                icon: Icon(Icons.download, color: AppColors.success),
                onPressed: _exportData,
                tooltip: 'تصدير البيانات',
              ),
              // زر إصلاح المحادثات
              IconButton(
                icon: Icon(Icons.build, color: AppColors.warning),
                onPressed: _fixConversations,
                tooltip: 'إصلاح المحادثات المفقودة',
              ),
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

          // أزرار التصفية
          Row(
            children: [
              // تصفية حسب الحالة
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'الحالة',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('جميع الحالات')),
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('قيد المراجعة'),
                    ),
                    DropdownMenuItem(
                      value: 'under_review',
                      child: Text('قيد الدراسة'),
                    ),
                    DropdownMenuItem(
                      value: 'approved',
                      child: Text('موافق عليه'),
                    ),
                    DropdownMenuItem(value: 'rejected', child: Text('مرفوض')),
                    DropdownMenuItem(value: 'completed', child: Text('مكتمل')),
                    DropdownMenuItem(value: 'cancelled', child: Text('ملغى')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value ?? 'all';
                      _applyFilters();
                    });
                  },
                ),
              ),

              const SizedBox(width: 12),

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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickStat('الإجمالي', _requests.length, AppColors.primary),
              _buildQuickStat(
                'معلقة',
                _requests.where((r) => r.status == 'pending').length,
                AppColors.warning,
              ),
              _buildQuickStat(
                'قيد الدراسة',
                _requests.where((r) => r.status == 'under_review').length,
                AppColors.info,
              ),
              _buildQuickStat(
                'موافق عليها',
                _requests.where((r) => r.status == 'approved').length,
                AppColors.success,
              ),
              _buildQuickStat(
                'غير مقروءة',
                _requests.where((r) => r.hasUnreadMessages).length,
                AppColors.error,
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
    final year = localDateTime.year.toString().substring(2); // آخر رقمين من السنة
    
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

  // عرض الإحصائيات التفصيلية
  void _showDetailedStats() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.analytics, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('إحصائيات طلبات الجملة'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow('إجمالي الطلبات', '${_requests.length}', AppColors.primary),
              _buildStatRow('الطلبات المعلقة', '${_requests.where((r) => r.status == 'pending').length}', AppColors.warning),
              _buildStatRow('قيد الدراسة', '${_requests.where((r) => r.status == 'under_review').length}', AppColors.info),
              _buildStatRow('موافق عليها', '${_requests.where((r) => r.status == 'approved').length}', AppColors.success),
              _buildStatRow('مرفوضة', '${_requests.where((r) => r.status == 'rejected').length}', AppColors.error),
              _buildStatRow('مكتملة', '${_requests.where((r) => r.status == 'completed').length}', AppColors.success),
              const Divider(),
              _buildStatRow('طلبات بها رسائل غير مقروءة', '${_requests.where((r) => r.hasUnreadMessages).length}', AppColors.warning),
              _buildStatRow('إجمالي الكمية المطلوبة', '${_requests.fold(0, (sum, r) => sum + r.quantity)} قطعة', AppColors.info),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // تصدير البيانات
  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.download, color: AppColors.success),
            const SizedBox(width: 8),
            const Text('تصدير بيانات طلبات الجملة'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('اختر نوع التصدير:'),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.table_chart, color: AppColors.primary),
              title: const Text('تصدير كـ Excel'),
              subtitle: const Text('ملف جدولي للتحليل'),
              onTap: () {
                Navigator.of(context).pop();
                _exportToExcel();
              },
            ),
            ListTile(
              leading: Icon(Icons.description, color: AppColors.info),
              title: const Text('تصدير كـ PDF'),
              subtitle: const Text('تقرير مطبوع'),
              onTap: () {
                Navigator.of(context).pop();
                _exportToPDF();
              },
            ),
            ListTile(
              leading: Icon(Icons.code, color: AppColors.warning),
              title: const Text('تصدير كـ JSON'),
              subtitle: const Text('للاستخدام البرمجي'),
              onTap: () {
                Navigator.of(context).pop();
                _exportToJSON();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _exportToExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم إضافة ميزة تصدير Excel في التحديث القادم'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _exportToPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم إضافة ميزة تصدير PDF في التحديث القادم'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _exportToJSON() {
    try {
      final jsonData = {
        'export_date': DateTime.now().toIso8601String(),
        'total_requests': _requests.length,
        'requests': _requests.map((r) => r.toJson()).toList(),
      };
      
      // طباعة البيانات في Console (يمكن استبدالها بحفظ ملف)
      print('JSON Export Data:');
      print(jsonData);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تصدير البيانات كـ JSON - راجع Console'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تصدير البيانات: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // إصلاح المحادثات المفقودة
  void _fixConversations() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.build, color: AppColors.warning),
            const SizedBox(width: 8),
            const Text('إصلاح المحادثات المفقودة'),
          ],
        ),
        content: const Text(
          'سيتم إنشاء المحادثات المفقودة لجميع طلبات الجملة. '
          'هذا سيحل مشكلة عدم ظهور الرسائل وعدم القدرة على إرسال رسائل جديدة.\n\n'
          'هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performConversationFix();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: const Text('إصلاح'),
          ),
        ],
      ),
    );
  }

  Future<void> _performConversationFix() async {
    try {
      // عرض شاشة الانتظار
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('جاري إصلاح المحادثات...'),
            ],
          ),
        ),
      );

      // تشغيل إصلاح المحادثات
      await _wholesaleService.createMissingConversations();

      // إغلاق شاشة الانتظار
      if (mounted) {
        Navigator.of(context).pop();
      }

      // إعادة تحميل الطلبات
      await _loadRequests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إصلاح المحادثات بنجاح - يمكنك الآن إرسال الرسائل'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // إغلاق شاشة الانتظار في حالة الخطأ
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إصلاح المحادثات: $e'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
