import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/order_thread.dart';
import '../../../core/services/order_service.dart';
import '../../../core/debug/order_debug.dart';
import 'order_chat_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();
  List<OrderThread> _orders = [];
  List<OrderThread> _filteredOrders = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedType = 'all';
  String _selectedUnreadFilter = 'all'; // إضافة فلتر للرسائل غير المقروءة
  String _selectedNewFilter = 'all'; // فلتر للطلبات الجديدة

  // Stream subscription للتحديثات في الوقت الفعلي
  StreamSubscription<List<OrderThread>>? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _startListening();
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _orderService.stopRealtimeSubscriptions();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // تشغيل اختبار شامل لتشخيص المشاكل
      print('🚀 بدء تشخيص نظام الطلبات...');
      await OrderDebug.testOrderConnection();

      // اختبار الاتصال أولاً
      final connectionTest = await _orderService.testDatabaseConnection();
      print('نتيجة اختبار الاتصال بالطلبات: $connectionTest');

      // جلب جميع الطلبات
      final orders = await _orderService.getOrders();
      print('📊 تم جلب ${orders.length} طلب');

      setState(() {
        _orders = orders;
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
            content: Text('خطأ في جلب الطلبات: $e'),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'إعادة المحاولة',
              textColor: Colors.white,
              onPressed: _loadOrders,
            ),
          ),
        );
      }
    }
  }

  void _startListening() {
    // بدء التحديثات في الوقت الفعلي
    _orderService.startRealtimeSubscriptions();

    // الاستماع للـ stream
    _ordersSubscription = _orderService.ordersStream.listen((orders) {
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
          _applyFilters();
        });
        print('🔄 تم تحديث قائمة الطلبات في الشاشة: ${orders.length} طلب');
      }
    });
  }

  void _applyFilters() {
    var filtered = _orders;

    // تصفية حسب البحث
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((order) {
        final title = order.title.toLowerCase();
        final userName = order.userName?.toLowerCase() ?? '';
        final productNames = order.productNames?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();

        return title.contains(query) ||
            userName.contains(query) ||
            productNames.contains(query);
      }).toList();
    }

    // تصفية حسب الحالة
    if (_selectedStatus != 'all') {
      if (_selectedStatus == 'pending') {
        // دمج حالتي pending و processing في تصنيف واحد
        filtered = filtered
            .where(
              (order) =>
                  order.status == 'pending' || order.status == 'processing',
            )
            .toList();
      } else {
        filtered = filtered
            .where((order) => order.status == _selectedStatus)
            .toList();
      }
    }

    // تصفية حسب النوع
    if (_selectedType != 'all') {
      filtered = filtered
          .where((order) => order.orderType == _selectedType)
          .toList();
    }

    // تصفية حسب حالة الرسائل غير المقروءة
    if (_selectedUnreadFilter == 'unread_only') {
      filtered = filtered.where((order) => order.hasUnreadMessages).toList();
    } else if (_selectedUnreadFilter == 'read_only') {
      filtered = filtered.where((order) => !order.hasUnreadMessages).toList();
    }

    // فلتر الطلبات الجديدة
    if (_selectedNewFilter == 'new_only') {
      filtered = filtered.where((order) => order.isNewOrder).toList();
    } else if (_selectedNewFilter == 'responded_only') {
      filtered = filtered.where((order) => !order.isNewOrder).toList();
    }

    // ترتيب المحادثات: الطلبات الجديدة أولاً، ثم الرسائل غير المقروءة، ثم حسب التحديث الأخير
    filtered.sort((a, b) {
      // إذا كان أحد الطلبات جديد (لم يرسل له المشرف رسالة) والآخر لا
      if (a.isNewOrder && !b.isNewOrder) {
        return -1; // a أولاً
      } else if (!a.isNewOrder && b.isNewOrder) {
        return 1; // b أولاً
      }

      // إذا كان كلاهما جديد أو كلاهما ليس جديد، رتب حسب الرسائل غير المقروءة
      if (a.hasUnreadMessages && !b.hasUnreadMessages) {
        return -1; // a أولاً
      } else if (!a.hasUnreadMessages && b.hasUnreadMessages) {
        return 1; // b أولاً
      }

      // إذا كان كلاهما لديه أو لا يملك رسائل غير مقروءة، رتب حسب آخر تحديث
      final aTime = a.lastMessageAt ?? a.updatedAt;
      final bTime = b.lastMessageAt ?? b.updatedAt;
      return bTime.compareTo(aTime);
    });

    setState(() {
      _filteredOrders = filtered;
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

          // قائمة الطلبات
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                ? _buildEmptyState()
                : _buildOrdersList(),
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
          // عنوان القسم
          Row(
            children: [
              Icon(Icons.shopping_cart, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'الطلبات',
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
              hintText: 'البحث في الطلبات...',
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
          Column(
            children: [
              // الصف الأول: الحالة والنوع
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
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('جميع الحالات'),
                        ),
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('قيد المراجعة'),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('مكتمل'),
                        ),
                        DropdownMenuItem(
                          value: 'cancelled',
                          child: Text('ملغى'),
                        ),
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

                  // تصفية حسب النوع
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        labelText: 'النوع',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('جميع الأنواع'),
                        ),
                        DropdownMenuItem(value: 'retail', child: Text('تجزئة')),
                        DropdownMenuItem(
                          value: 'delivery',
                          child: Text('توصيل'),
                        ),
                        DropdownMenuItem(
                          value: 'mobileCredit',
                          child: Text('رصيد جوال'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value ?? 'all';
                          _applyFilters();
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  // زر التحديث
                  IconButton(
                    icon: Icon(Icons.refresh, color: AppColors.primary),
                    onPressed: _loadOrders,
                    tooltip: 'تحديث',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // الصف الثاني: فلتر الرسائل غير المقروءة والطلبات الجديدة
              Row(
                children: [
                  // تصفية حسب حالة القراءة
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedUnreadFilter,
                      decoration: InputDecoration(
                        labelText: 'حالة المحادثة',
                        prefixIcon: Icon(
                          Icons.mark_email_unread,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Row(
                            children: [
                              Icon(Icons.all_inbox, size: 16),
                              SizedBox(width: 8),
                              Text('جميع المحادثات'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'unread_only',
                          child: Row(
                            children: [
                              Icon(
                                Icons.fiber_new,
                                size: 16,
                                color: AppColors.info,
                              ),
                              SizedBox(width: 8),
                              Text('رسائل جديدة فقط'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'read_only',
                          child: Row(
                            children: [
                              Icon(
                                Icons.mark_email_read,
                                size: 16,
                                color: Colors.green,
                              ),
                              SizedBox(width: 8),
                              Text('مقروءة فقط'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedUnreadFilter = value ?? 'all';
                          _applyFilters();
                        });
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  // فلتر الطلبات الجديدة
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedNewFilter,
                      decoration: InputDecoration(
                        labelText: 'الطلبات الجديدة',
                        prefixIcon: Icon(
                          Icons.new_releases,
                          color: AppColors.warning,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Row(
                            children: [
                              Icon(Icons.all_inbox, size: 16),
                              SizedBox(width: 8),
                              Text('جميع الطلبات'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'new_only',
                          child: Row(
                            children: [
                              Icon(
                                Icons.new_releases,
                                size: 16,
                                color: AppColors.warning,
                              ),
                              SizedBox(width: 8),
                              Text('جديدة فقط'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'responded_only',
                          child: Row(
                            children: [
                              Icon(Icons.reply, size: 16, color: Colors.green),
                              SizedBox(width: 8),
                              Text('تم الرد عليها'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedNewFilter = value ?? 'all';
                          _applyFilters();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // إحصائيات سريعة
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickStat(
                      'الإجمالي',
                      _orders.length,
                      AppColors.primary,
                    ),
                    _buildQuickStat(
                      'قيد المراجعة',
                      _orders
                          .where(
                            (o) =>
                                o.status == 'pending' ||
                                o.status == 'processing',
                          )
                          .length,
                      AppColors.info,
                    ),
                    _buildQuickStat(
                      'مكتملة',
                      _orders.where((o) => o.status == 'completed').length,
                      AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDetailedUnreadStat(),
                    _buildQuickStat(
                      'مقروءة',
                      _orders.where((o) => !o.hasUnreadMessages).length,
                      AppColors.success.withValues(alpha: 0.7),
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

  Widget _buildDetailedUnreadStat() {
    final unreadThreadsCount = _orders.where((o) => o.hasUnreadMessages).length;
    final totalUnreadMessages = _orders
        .where((o) => o.hasUnreadMessages)
        .fold<int>(0, (sum, order) => sum + order.unreadCount);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedUnreadFilter = 'unread_only';
          _applyFilters();
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: unreadThreadsCount > 0
              ? AppColors.info.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: unreadThreadsCount > 0
              ? Border.all(color: AppColors.info.withValues(alpha: 0.3))
              : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fiber_new, color: AppColors.info, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$unreadThreadsCount',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
            Text(
              'محادثات جديدة',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.text.withValues(alpha: 0.7),
              ),
            ),
            if (totalUnreadMessages > 0)
              Text(
                '$totalUnreadMessages رسالة',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.info.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: AppColors.text.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد طلبات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.text.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر طلبات المستخدمين هنا عندما يقومون بإنشاء طلبات جديدة',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.text.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          // زر إعادة التحميل
          ElevatedButton.icon(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة تحميل الطلبات'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          // معلومات تشخيصية
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.info_outline, color: AppColors.info),
                const SizedBox(height: 8),
                Text(
                  'التشخيص',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'إذا كنت تتوقع وجود طلبات، تحقق من:\n• اتصال قاعدة البيانات\n• تصاريح الوصول (RLS Policies)\n• سجلات وحدة التحكم للأخطاء',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.text.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredOrders.length,
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(OrderThread order) {
    final hasUnreadMessages = order.hasUnreadMessages;
    final isNewConversation = hasUnreadMessages && order.unreadCount > 0;
    final isNewOrder = order.isNewOrder; // طلب جديد لم يرسل له المشرف رسالة

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: (hasUnreadMessages || isNewOrder) ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isNewOrder
              ? AppColors
                    .warning // لون برتقالي للطلبات الجديدة
              : hasUnreadMessages
              ? AppColors.info
              : _getStatusColor(order.status).withValues(alpha: 0.3),
          width: (hasUnreadMessages || isNewOrder) ? 2 : 1,
        ),
      ),
      color: isNewOrder
          ? AppColors.warning.withValues(
              alpha: 0.1,
            ) // خلفية برتقالية فاتحة للطلبات الجديدة
          : hasUnreadMessages
          ? AppColors.info.withValues(alpha: 0.08)
          : AppColors.cardBackground,
      child: InkWell(
        onTap: () => _openOrderChat(order),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: hasUnreadMessages
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.info.withValues(alpha: 0.1),
                      AppColors.info.withValues(alpha: 0.03),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // شريط علوي للمحادثات الجديدة
                if (isNewConversation)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.info,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.info.withValues(alpha: 0.3),
                          blurRadius: 8,
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
                        const SizedBox(width: 8),
                        Text(
                          'محادثة جديدة - ${order.unreadCount} رسالة جديدة',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.fiber_new,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                // رأس الطلب
                Row(
                  children: [
                    // أيقونة النوع
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getTypeColor(
                          order.orderType,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getTypeIcon(order.orderType),
                        color: _getTypeColor(order.orderType),
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
                              // مؤشر الطلب الجديد
                              if (isNewOrder) ...[
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
                              // مؤشر الرسائل غير المقروءة
                              if (hasUnreadMessages && !isNewOrder) ...[
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: AppColors.info,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  order.displayTitle,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        (hasUnreadMessages || isNewOrder)
                                        ? FontWeight.w900
                                        : FontWeight.bold,
                                    color: isNewOrder
                                        ? AppColors.warning
                                        : hasUnreadMessages
                                        ? AppColors.info
                                        : AppColors.text,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // شارة "جديد" للطلبات الجديدة
                              if (isNewOrder)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
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
                          const SizedBox(height: 4),
                          Text(
                            order.displayUserName,
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
                        color: _getStatusColor(order.status),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        order.displayStatus,
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
                if (order.productNames != null &&
                    order.productNames!.isNotEmpty) ...[
                  Text(
                    'المنتجات: ${order.productNames}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.text.withValues(alpha: 0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],

                if (order.summary != null && order.summary!.isNotEmpty) ...[
                  Text(
                    order.summary!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.text.withValues(alpha: 0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],

                // آخر رسالة (للمحادثات التي تحتوي على رسائل)
                if (order.lastMessage != null &&
                    order.lastMessage!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: hasUnreadMessages
                          ? AppColors.info.withValues(alpha: 0.1)
                          : AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasUnreadMessages
                            ? AppColors.info.withValues(alpha: 0.3)
                            : AppColors.secondary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 16,
                              color: hasUnreadMessages
                                  ? AppColors.info
                                  : AppColors.text.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'آخر رسالة:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: hasUnreadMessages
                                    ? AppColors.info
                                    : AppColors.text.withValues(alpha: 0.7),
                              ),
                            ),
                            const Spacer(),
                            if (order.lastMessageAt != null)
                              Text(
                                _formatDateTime(order.lastMessageAt!),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.text.withValues(alpha: 0.5),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          order.lastMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: hasUnreadMessages
                                ? AppColors.text
                                : AppColors.text.withValues(alpha: 0.8),
                            fontWeight: hasUnreadMessages
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],

                // سطر المعلومات السفلي
                Row(
                  children: [
                    // نوع الطلب
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getTypeColor(
                          order.orderType,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getTypeColor(order.orderType),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        order.displayOrderType,
                        style: TextStyle(
                          color: _getTypeColor(order.orderType),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // وقت آخر تحديث
                    Expanded(
                      child: Text(
                        'آخر تحديث: ${_formatDateTime(order.updatedAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.text.withValues(alpha: 0.5),
                        ),
                      ),
                    ),

                    // عدد الرسائل غير المقروءة
                    if (order.unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.info.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              order.unreadCount > 99
                                  ? '99+'
                                  : '${order.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(width: 12),

                    // سهم التنقل
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasUnreadMessages
                            ? AppColors.info.withValues(alpha: 0.1)
                            : AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: hasUnreadMessages
                            ? AppColors.info
                            : AppColors.text.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
      case 'processing':
        return AppColors.info; // نفس اللون للحالتين
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

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'retail':
        return Icons.shopping_cart;
      case 'delivery':
        return Icons.local_shipping;
      case 'mobileCredit':
        return Icons.phone_android;
      default:
        return Icons.shopping_bag;
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

  void _openOrderChat(OrderThread order) async {
    try {
      // تحديث حالة الرسائل كمقروءة قبل فتح المحادثة
      if (order.hasUnreadMessages) {
        final updatedCount = await _orderService.markOrderMessagesAsRead(
          order.id,
        );
        print(
          '✅ تم تحديد $updatedCount رسالة في الطلب ${order.id} كمقروءة قبل فتح المحادثة',
        );
      }

      // فتح شاشة المحادثة
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => OrderChatScreen(order: order)),
      );

      // إعادة تحميل الطلبات عند العودة لتحديث العدادات
      if (mounted) {
        await _loadOrders();
      }
    } catch (e) {
      print('❌ خطأ في فتح المحادثة: $e');
      // فتح المحادثة حتى لو فشل تحديث حالة القراءة
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OrderChatScreen(order: order),
          ),
        );
        await _loadOrders();
      }
    }
  }
}
