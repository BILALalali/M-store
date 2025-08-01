import 'package:flutter/material.dart';
import 'product_details_screen.dart';
import 'product_model.dart';
import 'util_screen.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  // قائمة المنتجات متاحة بشكل ثابت
  static List<Product> get products => [
    Product(
      name: 'سامسونج جالاكسي S23',
      images: [
        'https://images.samsung.com/is/image/samsung/p6pim/levant/galaxy-s23/gallery/levant-galaxy-s23-s911-sm-s911bzgdmea-thumb-535978237',
        'https://images.samsung.com/is/image/samsung/p6pim/levant/galaxy-s23/gallery/levant-galaxy-s23-s911-sm-s911bzgdmea-2-thumb',
        'https://images.samsung.com/is/image/samsung/p6pim/levant/galaxy-s23/gallery/levant-galaxy-s23-s911-sm-s911bzgdmea-3-thumb',
      ],
      price: 1200.0,
      quantity: 3,
      category: 'موبايلات',
      description:
          'هاتف ذكي متطور بشاشة AMOLED وكاميرا عالية الدقة وسعة بطارية كبيرة.',
    ),
    Product(
      name: 'شاومي ريدمي نوت 12',
      images: [
        'https://fdn2.gsmarena.com/vv/pics/xiaomi/xiaomi-redmi-note-12-4g-1.jpg',
        'https://fdn2.gsmarena.com/vv/pics/xiaomi/xiaomi-redmi-note-12-4g-2.jpg',
      ],
      price: 350.0,
      quantity: 5,
      category: 'موبايلات',
      description:
          'موبايل اقتصادي بشاشة كبيرة وبطارية تدوم طويلاً وكاميرا ثلاثية.',
    ),
    Product(
      name: 'آيفون 14 برو',
      images: [
        'https://store.storeimages.cdn-apple.com/4668/as-images.apple.com/is/iphone-14-pro-max-deep-purple-select?wid=940&hei=1112&fmt=png-alpha&.v=1660753619946',
        'https://store.storeimages.cdn-apple.com/4668/as-images.apple.com/is/iphone-14-pro-max-silver-select?wid=940&hei=1112&fmt=png-alpha&.v=1660753619946',
      ],
      price: 1800.0,
      quantity: 2,
      category: 'موبايلات',
      description:
          'أحدث هواتف آبل مع شاشة ProMotion وكاميرا احترافية ومعالج قوي.',
    ),
    Product(
      name: 'كفر شفاف آيفون',
      images: [
        'https://images.unsplash.com/photo-1517336714731-489689fd1ca8',
        'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?2',
      ],
      price: 10.0,
      quantity: 10,
      category: 'كفرات وحمايات',
      description:
          'كفر شفاف عالي الجودة يوفر حماية ممتازة مع الحفاظ على شكل الجهاز.',
    ),
    Product(
      name: 'شاحن سريع 25W',
      images: ['https://images.unsplash.com/photo-1510557880182-3d4d3c1b3ed4'],
      price: 20.0,
      quantity: 7,
      category: 'شواحن وكوابل',
      description: 'شاحن سريع بقوة 25 واط متوافق مع معظم أجهزة أندرويد.',
    ),
    Product(
      name: 'سماعة بلوتوث',
      images: [
        'https://images.unsplash.com/photo-1511367461989-f85a21fda167',
        'https://images.unsplash.com/photo-1511367461989-f85a21fda167?2',
      ],
      price: 35.0,
      quantity: 5,
      category: 'سماعات',
      description: 'سماعة لاسلكية بصوت نقي وعزل ضوضاء ومدة تشغيل طويلة.',
    ),
    Product(
      name: 'بطاقة شحن MTN 5000',
      images: ['https://cdn-icons-png.flaticon.com/512/1041/1041916.png'],
      price: 5000.0,
      quantity: 15,
      category: 'بطاقات وشحن رصيد',
      description: 'بطاقة شحن رصيد بقيمة 5000 ل.س لشبكة MTN.',
    ),
    Product(
      name: 'كابل USB-C أصلي',
      images: ['https://images.unsplash.com/photo-1519125323398-675f0ddb6308'],
      price: 8.0,
      quantity: 20,
      category: 'شواحن وكوابل',
      description: 'كابل USB-C أصلي لنقل البيانات والشحن السريع.',
    ),
    Product(
      name: 'حامل موبايل للسيارة',
      images: ['https://images.unsplash.com/photo-1509395176047-4a66953fd231'],
      price: 15.0,
      quantity: 8,
      category: 'إكسسوارات أخرى',
      description: 'حامل عملي لتثبيت الموبايل في السيارة بأمان وسهولة.',
    ),
  ];

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String selectedCategory = 'الكل';

  // تصفية المنتجات حسب البحث والفئة
  List<Product> get filteredProducts {
    String search = _searchController.text.trim();
    return HomeScreen.products.where((product) {
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
                onChanged: () => setState(() {}),
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
                        onCategoryChanged: (category) {
                          setState(() => selectedCategory = category);
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
