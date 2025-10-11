import 'package:flutter/material.dart';
import 'product_details_screen.dart';
import 'product_model.dart';
import 'util_screen.dart';
import '../../core/services/product_service.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String selectedCategory = 'الكل';

  // متغيرات لإدارة حالة التطبيق
  List<Product> _products = [];
  List<String> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // تحميل البيانات الأولية
  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // تحميل المنتجات والفئات في نفس الوقت
      final futures = await Future.wait([
        ProductService.getAllProducts(),
        ProductService.getCategories(),
      ]);

      setState(() {
        _products = futures[0] as List<Product>;
        // جلب الفئات من قاعدة البيانات (مع التأكد من عدم تكرار "الكل")
        final dbCategories = futures[1] as List<String>;
        // إضافة "الكل" فقط إذا لم تكن موجودة في قاعدة البيانات
        if (!dbCategories.contains('الكل')) {
          _categories = ['الكل', ...dbCategories];
        } else {
          _categories = dbCategories;
        }
        _isLoading = false;
      });
    } catch (e) {
      print('خطأ في تحميل البيانات: $e');
      setState(() {
        _errorMessage =
            'حدث خطأ في تحميل البيانات. سيتم استخدام البيانات المحلية.';
        _isLoading = false;
      });

      // محاولة تحميل البيانات المحلية
      try {
        final localProducts = await ProductService.getAllProducts();
        final localCategories = await ProductService.getCategories();

        setState(() {
          _products = localProducts;
          _categories = localCategories;
          _errorMessage = null;
        });
      } catch (localError) {
        print('خطأ في تحميل البيانات المحلية: $localError');
        setState(() {
          _errorMessage = 'فشل في تحميل البيانات. يرجى المحاولة مرة أخرى.';
        });
      }
    }
  }

  // البحث في المنتجات
  Future<void> _searchProducts(String query) async {
    if (query.trim().isEmpty) {
      await _loadInitialData();
      return;
    }

    try {
      setState(() {
        _errorMessage = null;
      });

      final searchResults = await ProductService.searchProducts(query);

      setState(() {
        _products = searchResults;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ في البحث: $e';
      });
    }
  }

  // تحميل المنتجات حسب الفئة
  Future<void> _loadProductsByCategory(String category) async {
    if (category == 'الكل') {
      await _loadInitialData();
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final categoryProducts = await ProductService.getProductsByCategory(
        category,
      );

      setState(() {
        _products = categoryProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ في تحميل الفئة: $e';
        _isLoading = false;
      });
    }
  }

  // تصفية المنتجات حسب البحث والفئة
  List<Product> get filteredProducts {
    String search = _searchController.text.trim();
    return _products.where((product) {
      final matchesCategory =
          selectedCategory == 'الكل' || product.category == selectedCategory;
      final matchesSearch =
          search.isEmpty ||
          product.name.contains(search) ||
          product.category.contains(search);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UtilScreen.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // الهيدر مع اللوجو (ثابت)
            Container(
              height: 70,
              color: UtilScreen.backgroundColor,
              child: const AppHeader(),
            ),
            // شريط البحث (ثابت)
            Container(
              height: 60,
              color: UtilScreen.backgroundColor,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: CustomSearchBar(
                controller: _searchController,
                onChanged: () {
                  final value = _searchController.text;
                  if (value.trim().isEmpty) {
                    _loadInitialData();
                  } else {
                    _searchProducts(value);
                  }
                },
              ),
            ),
            // المحتوى القابل للتمرير
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // بانر الإعلانات (غير ثابت)
                  const SliverToBoxAdapter(child: BannerAds()),
                  // شريط الفئات (غير ثابت)
                  SliverToBoxAdapter(
                    child: Container(
                      color: UtilScreen.backgroundColor,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: CategoryChips(
                        selectedCategory: selectedCategory,
                        dynamicCategories: _categories.isNotEmpty
                            ? _categories
                            : null,
                        onCategoryChanged: (category) {
                          setState(() => selectedCategory = category);
                          _loadProductsByCategory(category);
                        },
                      ),
                    ),
                  ),
                  // الشريط المتحرك للنص (ثابت عند التمرير)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: StickyHeaderDelegate(
                      child: Container(
                        color: UtilScreen.backgroundColor,
                        child: const ScrollingTextBanner(),
                      ),
                      minHeight: 60,
                      maxHeight: 60,
                    ),
                  ),
                  // عرض حالة التحميل أو الخطأ
                  if (_isLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    )
                  else if (_errorMessage != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.red[300],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadInitialData,
                                child: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (_products.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد منتجات متاحة حالياً',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    // قائمة المنتجات في عمودين
                    SliverPadding(
                      padding: const EdgeInsets.all(16.0),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final product = filteredProducts[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailsScreen(product: product),
                                ),
                              );
                            },
                            child: ProductCardTwoColumns(product: product),
                          );
                        }, childCount: filteredProducts.length),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
