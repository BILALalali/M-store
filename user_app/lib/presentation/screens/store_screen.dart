import 'package:flutter/material.dart';
import 'product_details_screen.dart';
import 'product_model.dart';

class StoreScreen extends StatefulWidget {
  StoreScreen({Key? key}) : super(key: key);

  // قائمة المنتجات متاحة بشكل ثابت
  static List<Product> get products => [
    Product(
      name: 'سامسونج جالاكسي S23',
      images: [
        'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9',
        'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?ixlib=rb-4.0.3',
        'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?ixlib=rb-4.0.3&auto=format&fit=crop&w=500',
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
        'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9',
        'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?ixlib=rb-4.0.3',
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
        'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9',
        'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?ixlib=rb-4.0.3',
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
        'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?ixlib=rb-4.0.3',
      ],
      price: 10.0,
      quantity: 10,
      category: 'كفرات وحمايات',
      description:
          'كفر شفاف عالي الجودة يوفر حماية ممتازة مع الحفاظ على شكل الجهاز.',
    ),
    Product(
      name: 'شاحن سريع 25W',
      images: ['https://images.unsplash.com/photo-1519125323398-675f0ddb6308'],
      price: 20.0,
      quantity: 7,
      category: 'شواحن وكوابل',
      description: 'شاحن سريع بقوة 25 واط متوافق مع معظم أجهزة أندرويد.',
    ),
    Product(
      name: 'سماعة بلوتوث',
      images: [
        'https://images.unsplash.com/photo-1511367461989-f85a21fda167',
        'https://images.unsplash.com/photo-1511367461989-f85a21fda167?ixlib=rb-4.0.3',
      ],
      price: 35.0,
      quantity: 5,
      category: 'سماعات',
      description: 'سماعة لاسلكية بصوت نقي وعزل ضوضاء ومدة تشغيل طويلة.',
    ),
    Product(
      name: 'بطاقة شحن MTN 5000',
      images: ['https://images.unsplash.com/photo-1519125323398-675f0ddb6308'],
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
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String selectedCategory = 'الكل';

  // ألوان الهوية البصرية
  static const Color primaryColor = Color(0xFF1EC6D9); // فيروزي
  static const Color beigeColor = Color(0xFFF5EEDC); // بيج
  static const Color backgroundColor = Color(0xFFF7F7F7); // رمادي فاتح

  // قائمة الفئات المتخصصة
  final List<String> categories = [
    'الكل',
    'موبايلات',
    'كفرات وحمايات',
    'شواحن وكوابل',
    'سماعات',
    'بطاقات وشحن رصيد',
    'إكسسوارات أخرى',
  ];

  // متغيرات البانر
  final List<String> bannerImages = [
    'https://images.unsplash.com/photo-1465101046530-73398c7f28ca',
    'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9',
    'https://images.unsplash.com/photo-1517336714731-489689fd1ca8',
  ];
  int _currentBanner = 0;
  final PageController _bannerController = PageController();

  // تصفية المنتجات حسب البحث والفئة
  List<Product> get filteredProducts {
    String search = _searchController.text.trim();
    return StoreScreen.products.where((product) {
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
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = screenWidth * 0.12;
    final fontSizeTitle = screenWidth * 0.048;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          'AL-MOSTAFA COMPANY',
                          style: TextStyle(
                            fontSize: fontSizeTitle + 2,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            fontFamily: 'Cairo',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/logo.png',
                        width: logoSize,
                        height: logoSize,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Banner
              Container(
                height: 120,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: PageView.builder(
                        controller: _bannerController,
                        itemCount: bannerImages.length,
                        onPageChanged: (index) {
                          setState(() => _currentBanner = index);
                        },
                        itemBuilder: (context, index) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                bannerImages[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: beigeColor,
                                      child: const Icon(
                                        Icons.image,
                                        size: 40,
                                        color: primaryColor,
                                      ),
                                    ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withOpacity(0.25),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 16,
                                top: 16,
                                child: Image.asset(
                                  'assets/logo.png',
                                  width: 36,
                                  height: 36,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    // مؤشر النقاط
                    Positioned(
                      bottom: 8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          bannerImages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentBanner == index ? 18 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: _currentBanner == index
                                  ? primaryColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منتج...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Categories
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            selectedCategory = category;
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: primaryColor.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? primaryColor : Colors.black54,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Products Grid
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailsScreen(product: product),
                          ),
                        );
                      },
                      child: ProductCard(product: product),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  static const Color primaryColor = Color(0xFF1EC6D9);
  static const Color beigeColor = Color(0xFFF5EEDC);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageHeight = screenWidth * 0.24;
    final fontSizeTitle = screenWidth * 0.042;
    final fontSizeBody = screenWidth * 0.034;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة المنتج
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child:
                (product.images.isNotEmpty && product.images.first.isNotEmpty)
                ? Image.network(
                    product.images.first,
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: imageHeight,
                      width: double.infinity,
                      color: beigeColor,
                      child: const Icon(
                        Icons.image,
                        size: 40,
                        color: primaryColor,
                      ),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: imageHeight,
                        width: double.infinity,
                        color: beigeColor,
                        child: const Center(
                          child: CircularProgressIndicator(color: primaryColor),
                        ),
                      );
                    },
                  )
                : Container(
                    height: imageHeight,
                    width: double.infinity,
                    color: beigeColor,
                    child: const Icon(
                      Icons.image,
                      size: 40,
                      color: primaryColor,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              product.name.isNotEmpty ? product.name : 'منتج بدون اسم',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSizeTitle,
                fontFamily: 'Cairo',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
            child: Text(
              product.category.isNotEmpty ? product.category : 'بدون فئة',
              style: TextStyle(
                fontSize: fontSizeBody,
                color: primaryColor,
                fontFamily: 'Cairo',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'السعر: ${product.price.toStringAsFixed(1)} ل.س',
              style: TextStyle(
                fontSize: fontSizeBody,
                color: Colors.black54,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'الكمية: ${product.quantity}',
              style: TextStyle(
                fontSize: fontSizeBody,
                color: Colors.black54,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
