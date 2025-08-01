import 'package:flutter/material.dart';
import 'product_model.dart';

class UtilScreen {
  // ألوان الهوية البصرية
  static const Color primaryColor = Color(0xFF1EC6D9); // فيروزي
  static const Color beigeColor = Color(0xFFF5EEDC); // بيج
  static const Color backgroundColor = Color(0xFFF7F7F7); // رمادي فاتح

  // قائمة الفئات المتخصصة
  static const List<String> categories = [
    'الكل',
    'موبايلات',
    'كفرات وحمايات',
    'شواحن وكوابل',
    'سماعات',
    'بطاقات وشحن رصيد',
    'إكسسوارات أخرى',
  ];

  // قائمة صور إعلانات
  static const List<String> bannerImages = [
    'https://images.unsplash.com/photo-1465101046530-73398c7f28ca',
    'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9',
    'https://images.unsplash.com/photo-1517336714731-489689fd1ca8',
  ];

  // حساب الأحجام المتجاوبة
  static double getResponsiveSize(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }

  // حساب أحجام الخطوط المتجاوبة
  static double getResponsiveFontSize(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }
}

// مكون شريط الفئات
class CategoryChips extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategoryChanged;

  const CategoryChips({
    Key? key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: UtilScreen.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = UtilScreen.categories[index];
          final isSelected = cat == selectedCategory;
          return ChoiceChip(
            label: Text(cat, style: const TextStyle(fontFamily: 'Cairo')),
            selected: isSelected,
            onSelected: (_) => onCategoryChanged(cat),
            selectedColor: UtilScreen.primaryColor,
            backgroundColor: UtilScreen.beigeColor,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
            ),
          );
        },
      ),
    );
  }
}

// مكون شريط البحث
class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const CustomSearchBar({
    Key? key,
    required this.controller,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        hintText: 'ابحث عن منتج أو فئة..',
        prefixIcon: const Icon(Icons.search, color: UtilScreen.primaryColor),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
      ),
      style: const TextStyle(fontFamily: 'Cairo'),
    );
  }
}

// مكون بانر الإعلانات
class BannerAds extends StatefulWidget {
  const BannerAds({Key? key}) : super(key: key);

  @override
  State<BannerAds> createState() => _BannerAdsState();
}

class _BannerAdsState extends State<BannerAds> {
  int _currentBanner = 0;
  final PageController _bannerController = PageController();

  @override
  void initState() {
    super.initState();
    _startBannerTimer();
  }

  void _startBannerTimer() {
    Future.delayed(const Duration(seconds: 7), () {
      if (mounted && _currentBanner < UtilScreen.bannerImages.length - 1) {
        setState(() {
          _currentBanner++;
        });
        _bannerController.animateToPage(
          _currentBanner,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else if (mounted) {
        setState(() {
          _currentBanner = 0;
        });
        _bannerController.animateToPage(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      _startBannerTimer();
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeBody = UtilScreen.getResponsiveFontSize(context, 0.042);

    return Column(
      children: [
        // بانر الإعلانات
        Container(
          height: 200,
          margin: const EdgeInsets.all(16),
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) {
              setState(() {
                _currentBanner = index;
              });
            },
            itemCount: UtilScreen.bannerImages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Image.network(
                        UtilScreen.bannerImages[index],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: UtilScreen.beigeColor,
                          child: const Icon(
                            Icons.image,
                            size: 48,
                            color: UtilScreen.primaryColor,
                          ),
                        ),
                      ),
                      // طبقة شفافة سوداء لتحسين قراءة النص
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                      // نص الإعلان
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Text(
                          'مساحة إعلانية ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSizeBody,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            shadows: [
                              Shadow(
                                offset: const Offset(1, 1),
                                blurRadius: 3,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // مؤشرات البانر
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            UtilScreen.bannerImages.length,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentBanner == index
                    ? UtilScreen.primaryColor
                    : Colors.grey.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// مكون بطاقة المنتج للعرض في عمودين
class ProductCardTwoColumns extends StatelessWidget {
  final Product product;

  const ProductCardTwoColumns({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final fontSizeTitle = UtilScreen.getResponsiveFontSize(context, 0.032);
    final fontSizeBody = UtilScreen.getResponsiveFontSize(context, 0.025);
    final fontSizePrice = UtilScreen.getResponsiveFontSize(context, 0.028);

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
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: product.images.isNotEmpty
                  ? Image.network(
                      product.images.first,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        color: UtilScreen.beigeColor,
                        child: const Icon(
                          Icons.image,
                          size: 32,
                          color: UtilScreen.primaryColor,
                        ),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      color: UtilScreen.beigeColor,
                      child: const Icon(
                        Icons.image,
                        size: 32,
                        color: UtilScreen.primaryColor,
                      ),
                    ),
            ),
          ),
          // معلومات المنتج
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSizeTitle,
                      fontFamily: 'Cairo',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    product.category,
                    style: TextStyle(
                      fontSize: fontSizeBody,
                      color: UtilScreen.primaryColor,
                      fontFamily: 'Cairo',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${product.price.toStringAsFixed(1)} ل.س',
                    style: TextStyle(
                      fontSize: fontSizePrice,
                      color: Colors.black87,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'الكمية: ${product.quantity}',
                    style: TextStyle(
                      fontSize: fontSizeBody,
                      color: Colors.black54,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// مكون الهيدر مع اللوجو
class AppHeader extends StatelessWidget {
  const AppHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = screenWidth * 0.11;
    final fontSizeTitle = UtilScreen.getResponsiveFontSize(context, 0.050);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 21.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: UtilScreen.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // اسم الشركة في سطر واحد
          Expanded(
            child: Text(
              'AL-MOSTAFA COMPANY',
              style: TextStyle(
                fontSize: fontSizeTitle,
                fontWeight: FontWeight.bold,
                color: UtilScreen.primaryColor,
                fontFamily: 'Cairo',
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 1),
          // اللوجو في الجهة اليمنى
          Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: UtilScreen.primaryColor.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/logo.png',
                width: logoSize,
                height: logoSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    color: UtilScreen.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.store,
                    size: logoSize * 0.5,
                    color: UtilScreen.primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// كلاس مساعد لجعل الهيدر ثابت
class StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

// مكون الشريط المتحرك للنص
class ScrollingTextBanner extends StatefulWidget {
  const ScrollingTextBanner({Key? key}) : super(key: key);

  @override
  State<ScrollingTextBanner> createState() => _ScrollingTextBannerState();
}

class _ScrollingTextBannerState extends State<ScrollingTextBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    );
    _animation =
        Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: const Offset(1.0, 0.0),
        ).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.linear),
        );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            UtilScreen.primaryColor.withOpacity(0.1),
            UtilScreen.primaryColor.withOpacity(0.2),
            UtilScreen.primaryColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: UtilScreen.primaryColor.withOpacity(0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: UtilScreen.primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(44),
        child: Stack(
          children: [
            // النص المتحرك
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(44),
                child: SlideTransition(
                  position: _animation,
                  child: Container(
                    height: 50,
                    child: Row(
                      children: [
                        const SizedBox(width: 21),
                        Expanded(
                          child: Text(
                            'كميات جملة متاحة من جميع المنتجات بأسعار تنافسية، اطلب شحنتك من خدمات',
                            style: TextStyle(
                              color: const Color(0xFF1E3A8A),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Cairo',
                              letterSpacing: 0.4,
                            ),
                            softWrap: false,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                        const SizedBox(width: 21),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // الأيقونة بجانب الشريط
            const SizedBox(width: 8),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: UtilScreen.backgroundColor, // خلفية صلبة لتغطية النص
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1.0,
                ),
              ),
              child: Icon(
                Icons.local_offer_outlined,
                color: Colors.orange.shade700,
                size: 25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
