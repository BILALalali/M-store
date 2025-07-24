import 'package:flutter/material.dart';
import 'store_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  static const Color primaryColor = Color(0xFF1EC6D9);
  static const Color beigeColor = Color(0xFFF5EEDC);
  static const Color backgroundColor = Color(0xFFF7F7F7);

  int _currentImage = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // جلب المنتجات المشابهة من نفس الفئة (عدا المنتج الحالي)
  List<Product> getSimilarProducts() {
    // استيراد المنتجات من StoreScreen (يفترض أن المنتجات متاحة بشكل ثابت)
    // هنا سنستخدم نفس منطق المنتجات الوهمية
    final allProducts = StoreScreen.products;
    return allProducts
        .where(
          (p) =>
              p.category == widget.product.category &&
              p.name != widget.product.name,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final similarProducts = getSimilarProducts();
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor),
        title: Text(
          product.name,
          style: const TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // سلايدر صور المنتج
              Center(
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: product.images.length,
                        onPageChanged: (index) {
                          setState(() => _currentImage = index);
                        },
                        itemBuilder: (context, index) {
                          final imageUrl = product.images[index];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    height: 180,
                                    width: 180,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    height: 180,
                                    width: 180,
                                    color: beigeColor,
                                    child: const Icon(
                                      Icons.image,
                                      size: 60,
                                      color: primaryColor,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    // صور مصغرة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(product.images.length, (index) {
                        final imageUrl = product.images[index];
                        return GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: _currentImage == index
                                ? const EdgeInsets.all(2)
                                : EdgeInsets.zero,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _currentImage == index
                                    ? primaryColor
                                    : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 40,
                                      height: 40,
                                      color: beigeColor,
                                      child: const Icon(
                                        Icons.image,
                                        size: 20,
                                        color: primaryColor,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'الفئة: ${product.category}',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'السعر: ${product.price.toStringAsFixed(1)} ل.س',
                style: const TextStyle(
                  fontSize: 17,
                  color: Colors.black87,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'الكمية المتوفرة: ${product.quantity}',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black45,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'الوصف:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                product.description,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تنفيذ عملية الشراء (وهمية)'),
                        ),
                      );
                    },
                    child: const Text(
                      'شراء الآن',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Cairo',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              // منتجات مشابهة
              if (similarProducts.isNotEmpty) ...[
                const SizedBox(height: 36),
                const Text(
                  'منتجات مشابهة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: similarProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final p = similarProducts[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailsScreen(product: p),
                            ),
                          );
                        },
                        child: Container(
                          width: 110,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(color: beigeColor, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(14),
                                  topRight: Radius.circular(14),
                                ),
                                child: p.images.isNotEmpty
                                    ? Image.network(
                                        p.images.first,
                                        height: 60,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        height: 60,
                                        width: double.infinity,
                                        color: beigeColor,
                                        child: const Icon(
                                          Icons.image,
                                          size: 30,
                                          color: primaryColor,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                ),
                                child: Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    fontFamily: 'Cairo',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                ),
                                child: Text(
                                  '${p.price.toStringAsFixed(1)} ل.س',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                    fontFamily: 'Cairo',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
