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
      filtered = filtered
          .where((order) => order.status == _selectedStatus)
          .toList();
    }

    // تصفية حسب النوع
    if (_selectedType != 'all') {
      filtered = filtered
          .where((order) => order.orderType == _selectedType)
          .toList();
    }

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
                      value: 'processing',
                      child: Text('قيد المعالجة'),
                    ),
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
                    DropdownMenuItem(value: 'all', child: Text('جميع الأنواع')),
                    DropdownMenuItem(value: 'retail', child: Text('تجزئة')),
                    DropdownMenuItem(value: 'delivery', child: Text('توصيل')),
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

          const SizedBox(height: 8),

          // إحصائيات سريعة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickStat('الإجمالي', _orders.length, AppColors.primary),
              _buildQuickStat(
                'معلقة',
                _orders.where((o) => o.status == 'pending').length,
                AppColors.warning,
              ),
              _buildQuickStat(
                'مكتملة',
                _orders.where((o) => o.status == 'completed').length,
                AppColors.success,
              ),
              _buildQuickStat(
                'غير مقروءة',
                _orders.where((o) => o.hasUnreadMessages).length,
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: hasUnreadMessages ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasUnreadMessages
              ? AppColors.warning
              : _getStatusColor(order.status),
          width: hasUnreadMessages ? 3 : 1,
        ),
      ),
      color: hasUnreadMessages
          ? AppColors.warning.withValues(alpha: 0.05)
          : AppColors.cardBackground,
      child: InkWell(
        onTap: () => _openOrderChat(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                                order.displayTitle,
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

                  // الوقت
                  Text(
                    _formatDateTime(order.updatedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.text.withValues(alpha: 0.5),
                    ),
                  ),

                  const Spacer(),

                  // عدد الرسائل غير المقروءة
                  if (order.unreadCount > 0)
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
                            order.unreadCount > 99
                                ? '99+ رسالة'
                                : '${order.unreadCount} رسالة',
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
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => OrderChatScreen(order: order)),
    );

    // إعادة تحميل الطلبات عند العودة
    if (mounted) {
      await _loadOrders();
    }
  }
}
