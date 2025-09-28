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
    print('🎬 ==== تهيئة شاشة محادثة طلب الجملة ====');
    print('📋 معلومات طلب الجملة:');
    print('   - ID: ${widget.request.id}');
    print('   - Product Name: ${widget.request.productName}');
    print('   - User ID: ${widget.request.userId}');
    print('   - User Name: ${widget.request.userName}');
    print('   - Status: ${widget.request.status}');
    print('   - Quantity: ${widget.request.quantity}');
    
    _currentRequest = widget.request;
    _loadMessages();
    _startListening();

    // تعيين الرسائل كمقروءة عند فتح المحادثة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  @override
  void dispose() {
    _wholesaleService.stopListening();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🚀 ==== بدء تحميل رسائل طلب الجملة في واجهة المشرف ====');
      print('📋 معرف طلب الجملة: ${widget.request.id}');
      print('📋 اسم المنتج: ${widget.request.productName}');
      print('👤 معرف المستخدم: ${widget.request.userId}');
      print('👤 اسم المستخدم: ${widget.request.userName}');

      final messages = await _wholesaleService.getWholesaleMessages(widget.request.id);

      print('=== نتيجة جلب رسائل طلب الجملة ===');
      print('عدد الرسائل المستلمة: ${messages.length}');
      
      if (messages.isNotEmpty) {
        print('📋 تفاصيل رسائل طلب الجملة:');
        for (int i = 0; i < messages.length; i++) {
          final msg = messages[i];
          print(
            '   ${i + 1}. ${msg.senderType}: ${msg.message} (${msg.detailedTime})',
          );
        }
      } else {
        print('⚠️ لم يتم العثور على أي رسائل لطلب الجملة');
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
      
      print('✅ انتهاء تحميل رسائل طلب الجملة في واجهة المشرف');
    } catch (e) {
      print('❌ خطأ في تحميل رسائل طلب الجملة: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في جلب رسائل طلب الجملة: $e'),
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

    _wholesaleService.startListeningToWholesaleMessages(widget.request.id, (messages) {
      if (mounted) {
        print('=== تحديث مباشر لرسائل طلب الجملة ===');
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
    if (_currentRequest == null) return;

    try {
      await _wholesaleService.markWholesaleMessagesAsRead(_currentRequest!.id);
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
      final sentMessage = await _wholesaleService.sendWholesaleMessage(
        requestId: widget.request.id,
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
      await _wholesaleService.markWholesaleMessagesAsRead(widget.request.id);

      // إظهار رسالة نجاح
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال رسالة طلب الجملة بنجاح'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إرسال رسالة طلب الجملة: $e'),
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

  Future<void> _updateRequestStatus(String newStatus) async {
    try {
      final success = await _wholesaleService.updateWholesaleRequestStatus(
        widget.request.id,
        newStatus,
      );
      if (success && mounted) {
        setState(() {
          _currentRequest = _currentRequest?.copyWith(status: newStatus);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث حالة الطلب إلى ${_getStatusDisplayName(newStatus)}'),
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
      case 'under_review':
        return 'قيد الدراسة';
      case 'approved':
        return 'موافق عليه';
      case 'rejected':
        return 'مرفوض';
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
          // معلومات طلب الجملة
          _buildRequestInfo(),

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
            _currentRequest?.displayTitle ?? 'طلب جملة',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            _currentRequest?.displayUserName ?? '',
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
        
        // قائمة خيارات الحالة
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'refresh':
                _loadMessages();
                _startListening(); // إعادة تفعيل الاستماع
                break;
              case 'diagnose':
                _runDiagnostics();
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
            const PopupMenuItem(
              value: 'diagnose',
              child: Row(
                children: [
                  Icon(Icons.bug_report, color: AppColors.warning),
                  SizedBox(width: 8),
                  Text('تشخيص المشاكل'),
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
                  Text('رفض'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'status_completed',
              child: Row(
                children: [
                  Icon(Icons.done_all, color: AppColors.success),
                  SizedBox(width: 8),
                  Text('إكمال'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'status_cancelled',
              child: Row(
                children: [
                  Icon(Icons.highlight_off, color: AppColors.error),
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

  Widget _buildRequestInfo() {
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
                  _currentRequest?.userName?.isNotEmpty == true
                      ? _currentRequest!.userName![0].toUpperCase()
                      : 'ع',
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
                      _currentRequest?.displayUserName ?? 'عميل',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      'رقم طلب الجملة: ${_currentRequest?.id.substring(0, 8) ?? ''}',
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(_currentRequest?.status ?? 'pending'),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _currentRequest?.displayStatus ?? 'قيد المراجعة',
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

          const SizedBox(height: 12),

          // تفاصيل طلب الجملة
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // اسم المنتج
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'المنتج: ${_currentRequest?.productName ?? 'غير محدد'}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // الكمية المطلوبة
                Row(
                  children: [
                    Icon(
                      Icons.numbers,
                      size: 16,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currentRequest?.displayQuantity ?? 'الكمية: غير محددة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // الوصف
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
                        _currentRequest?.displayDescription ?? 'لا يوجد وصف',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.text.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // تاريخ الإنشاء
          Row(
            children: [
              const Spacer(),
              Text(
                'تاريخ الطلب: ${_formatDateTime(_currentRequest?.createdAt ?? DateTime.now())}',
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
            'ابدأ المحادثة مع العميل حول طلب الجملة',
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

  Widget _buildMessageBubble(WholesaleMessage message) {
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
                hintText: 'اكتب رسالتك للعميل...',
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
    final localDateTime = dateTime.toLocal();
    final day = localDateTime.day.toString().padLeft(2, '0');
    final month = localDateTime.month.toString().padLeft(2, '0');
    final year = localDateTime.year;
    final hour = localDateTime.hour.toString().padLeft(2, '0');
    final minute = localDateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  // تشخيص المشاكل لطلبات الجملة
  Future<void> _runDiagnostics() async {
    print('🔧 بدء تشخيص المشاكل لطلبات الجملة من واجهة المحادثة...');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري تشخيص مشاكل طلبات الجملة... تحقق من Console'),
        backgroundColor: AppColors.info,
        duration: Duration(seconds: 3),
      ),
    );

    await _wholesaleService.diagnoseWholesaleChatSystem();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم الانتهاء من تشخيص طلبات الجملة - راجع Console للتفاصيل'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
