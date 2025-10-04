import 'package:flutter/material.dart';
import '../../../core/models/game_card.dart';
import '../../../core/services/game_cards_service.dart';
import '../../../core/theme/app_colors.dart';
// import '../../../core/utils/util_screen.dart';
import 'add_game_card_screen.dart';
import 'edit_game_card_screen.dart';
import 'game_card_providers_screen.dart';

class GameCardsScreen extends StatefulWidget {
  const GameCardsScreen({super.key});

  @override
  State<GameCardsScreen> createState() => _GameCardsScreenState();
}

class _GameCardsScreenState extends State<GameCardsScreen>
    with TickerProviderStateMixin {
  List<GameCard> _cards = [];
  List<GameCard> _filteredCards = [];
  List<GameCardProvider> _providers = [];
  GameCardProvider? _selectedProvider;
  String _searchQuery = '';
  bool _isLoading = true;
  bool _showActiveOnly = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // جلب البطاقات ومقدمي الخدمة بشكل متوازي
      final results = await Future.wait([
        GameCardsService.getAllCards(),
        GameCardsService.getAllProviders(),
      ]);

      setState(() {
        _cards = results[0] as List<GameCard>;
        _providers = results[1] as List<GameCardProvider>;
        _filteredCards = _cards;
        _isLoading = false;
      });

      _filterCards();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _filterCards() {
    setState(() {
      _filteredCards = _cards.where((card) {
        // تصفية حسب مقدم الخدمة
        if (_selectedProvider != null &&
            card.providerId != _selectedProvider!.id) {
          return false;
        }

        // تصفية حسب الحالة النشطة
        if (_showActiveOnly && !card.isActive) {
          return false;
        }

        // تصفية حسب البحث
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return (card.cardName?.toLowerCase().contains(query) ?? false) ||
              (card.descriptionAr?.toLowerCase().contains(query) ?? false) ||
              (card.descriptionEn?.toLowerCase().contains(query) ?? false);
        }

        return true;
      }).toList();
    });
  }

  void _onProviderChanged(GameCardProvider? provider) {
    setState(() {
      _selectedProvider = provider;
    });
    _filterCards();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterCards();
  }

  void _onActiveOnlyChanged(bool value) {
    setState(() {
      _showActiveOnly = value;
    });
    _filterCards();
  }

  Future<void> _deleteCard(GameCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف البطاقة "${card.cardName}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await GameCardsService.deleteCard(card.id!);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف البطاقة بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في حذف البطاقة: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleCardStatus(GameCard card) async {
    try {
      await GameCardsService.toggleCardStatus(card.id!, !card.isActive);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              card.isActive ? 'تم إلغاء تفعيل البطاقة' : 'تم تفعيل البطاقة',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تغيير حالة البطاقة: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getProviderName(int? providerId) {
    if (providerId == null) return 'غير محدد';

    final provider = _providers.firstWhere(
      (p) => p.id == providerId,
      orElse: () => GameCardProvider(
        name: 'غير محدد',
        displayNameAr: 'غير محدد',
        displayNameEn: 'Unknown',
      ),
    );
    return provider.displayNameAr ?? 'غير محدد';
  }

  // الحصول على بيانات مقدم الخدمة
  GameCardProvider? _getProvider(int? providerId) {
    if (providerId == null) return null;
    try {
      return _providers.firstWhere((p) => p.id == providerId);
    } catch (e) {
      return null;
    }
  }

  // بناء صورة مقدم الخدمة أو أيقونة افتراضية
  Widget _buildProviderLogo(GameCard card) {
    final provider = _getProvider(card.providerId);

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: card.isActive
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: provider?.logoUrl != null && provider!.logoUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                provider.logoUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.games,
                    color: card.isActive
                        ? AppColors.primary
                        : AppColors.text.withValues(alpha: 0.4),
                    size: 28,
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        card.isActive
                            ? AppColors.primary
                            : AppColors.text.withValues(alpha: 0.4),
                      ),
                    ),
                  );
                },
              ),
            )
          : Icon(
              Icons.games,
              color: card.isActive
                  ? AppColors.primary
                  : AppColors.text.withValues(alpha: 0.4),
              size: 28,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // رأس الصفحة
            _buildHeader(),

            // تبويبات
            _buildTabs(),

            // المحتوى
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildCardsTab(), _buildProvidersTab()],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddGameCardScreen(),
                  ),
                );

                if (result == true) {
                  await _loadData();
                }
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Icon(Icons.games, size: 32, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إدارة بطاقات الألعاب',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  'إدارة وإضافة وتعديل بطاقات ومقدمي خدمة الألعاب',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.text.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_filteredCards.length} بطاقة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.secondary.withValues(alpha: 0.2)),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.text.withValues(alpha: 0.6),
        indicatorColor: AppColors.primary,
        tabs: const [
          Tab(icon: Icon(Icons.games), text: 'البطاقات'),
          Tab(icon: Icon(Icons.business), text: 'مقدمو الخدمة'),
        ],
      ),
    );
  }

  Widget _buildCardsTab() {
    return Column(
      children: [
        // أدوات البحث والتصفية
        _buildFilters(),

        // قائمة البطاقات
        Expanded(child: _buildCardsList()),
      ],
    );
  }

  Widget _buildProvidersTab() {
    return const GameCardProvidersScreen();
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.secondary.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // حقل البحث
              Expanded(
                flex: 2,
                child: TextField(
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'البحث في البطاقات...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.text.withValues(alpha: 0.6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.secondary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // قائمة مقدمي الخدمة
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<GameCardProvider>(
                  value: _selectedProvider,
                  onChanged: _onProviderChanged,
                  decoration: InputDecoration(
                    labelText: 'مقدم الخدمة',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.secondary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<GameCardProvider>(
                      value: null,
                      child: Text('جميع مقدمي الخدمة'),
                    ),
                    ..._providers.map((provider) {
                      return DropdownMenuItem<GameCardProvider>(
                        value: provider,
                        child: Text(
                          provider.displayNameAr ?? 'غير محدد',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // فلتر البطاقات النشطة
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _showActiveOnly,
                    onChanged: (value) => _onActiveOnlyChanged(value ?? false),
                    activeColor: AppColors.primary,
                  ),
                  const Text('النشطة فقط'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredCards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.games_outlined,
              size: 64,
              color: AppColors.text.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedProvider != null
                  ? 'لا توجد بطاقات تطابق البحث'
                  : 'لا توجد بطاقات',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.text.withValues(alpha: 0.6),
              ),
            ),
            if (_searchQuery.isEmpty && _selectedProvider == null) ...[
              const SizedBox(height: 8),
              Text(
                'اضغط على زر + لإضافة بطاقة جديدة',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.text.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _filteredCards.length,
      itemBuilder: (context, index) {
        final card = _filteredCards[index];
        return _buildCardCard(card);
      },
    );
  }

  Widget _buildCardCard(GameCard card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: card.isActive
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.secondary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // صورة مقدم الخدمة أو أيقونة البطاقة
            _buildProviderLogo(card),

            const SizedBox(width: 20),

            // معلومات البطاقة
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          card.cardName ?? 'بطاقة غير محددة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: card.isActive
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          card.isActive ? 'نشط' : 'غير نشط',
                          style: TextStyle(
                            fontSize: 12,
                            color: card.isActive
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getProviderName(card.providerId),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'ترتيب: ${card.sortOrder ?? 0}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.text.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (card.descriptionAr != null &&
                      card.descriptionAr!.isNotEmpty)
                    Text(
                      card.descriptionAr!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.text.withValues(alpha: 0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // السعر والإجراءات
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${card.cardValue?.toStringAsFixed(0) ?? '0'}\$',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  'السعر: ${card.cardPrice?.toStringAsFixed(2) ?? '0.00'} ل.س',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // زر التعديل
                    IconButton(
                      onPressed: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditGameCardScreen(
                              card: card,
                              providers: _providers,
                            ),
                          ),
                        );

                        if (result == true) {
                          await _loadData();
                        }
                      },
                      icon: Icon(Icons.edit, color: AppColors.info, size: 20),
                      tooltip: 'تعديل',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.info.withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // زر تغيير الحالة
                    IconButton(
                      onPressed: () => _toggleCardStatus(card),
                      icon: Icon(
                        card.isActive ? Icons.visibility_off : Icons.visibility,
                        color: card.isActive
                            ? AppColors.warning
                            : AppColors.success,
                        size: 20,
                      ),
                      tooltip: card.isActive ? 'إلغاء التفعيل' : 'تفعيل',
                      style: IconButton.styleFrom(
                        backgroundColor:
                            (card.isActive
                                    ? AppColors.warning
                                    : AppColors.success)
                                .withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // زر الحذف
                    IconButton(
                      onPressed: () => _deleteCard(card),
                      icon: Icon(
                        Icons.delete,
                        color: AppColors.error,
                        size: 20,
                      ),
                      tooltip: 'حذف',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.error.withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
