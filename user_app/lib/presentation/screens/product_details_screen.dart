import 'package:flutter/material.dart';
import 'product_model.dart';
import 'orders_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  const ProductDetailsScreen({Key? key, required this.product})
    : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _currentImage = 0;
  final PageController _pageController = PageController();
  static const Color backgroundColor = Color(0xFFF7F7F7);

  // قائمة المنتجات الوهمية للمنتجات المشابهة
  static List<Product> get mockProducts => [
    Product(
      name: 'سامسونج جالاكسي S23',
      images: [
        'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9',
        'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?ixlib=rb-4.0.3',
      ],
      price: 1200.0,
      quantity: 3,
      category: 'موبايلات',
      description: 'هاتف ذكي متطور بشاشة AMOLED وكاميرا عالية الدقة.',
    ),
    Product(
      name: 'شاومي ريدمي نوت 12',
      images: ['https://images.unsplash.com/photo-1511707171634-5f897ff02aa9'],
      price: 350.0,
      quantity: 5,
      category: 'موبايلات',
      description: 'موبايل اقتصادي بشاشة كبيرة وبطارية تدوم طويلاً.',
    ),
    Product(
      name: 'كفر شفاف آيفون',
      images: ['https://images.unsplash.com/photo-1517336714731-489689fd1ca8'],
      price: 10.0,
      quantity: 10,
      category: 'كفرات وحمايات',
      description: 'كفر شفاف عالي الجودة يوفر حماية ممتازة.',
    ),
  ];

  // جلب المنتجات المشابهة من نفس الفئة (عدا المنتج الحالي)
  List<Product> getSimilarProducts() {
    return mockProducts
        .where(
          (p) =>
              p.category == widget.product.category &&
              p.name != widget.product.name,
        )
        .toList();
  }

  // إضافة المنتج إلى قائمة الطلبات
  void _addToCart() {
    // التحقق من أن المنتج غير موجود بالفعل في القائمة
    if (!OrdersScreen.pendingProducts.contains(widget.product)) {
      setState(() {
        OrdersScreen.pendingProducts.add(widget.product);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إضافة المنتج إلى قائمة الطلب'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('المنتج موجود بالفعل في قائمة الطلب'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final similarProducts = getSimilarProducts();
    final screenWidth = MediaQuery.of(context).size.width;
    final mainImageSize = screenWidth * 0.7;
    final thumbSize = screenWidth * 0.16;
    final similarCardWidth = screenWidth * 0.32;
    final similarImageHeight = similarCardWidth * 0.7;
    const Color beigeColor = Color(0xFFF5EEDC);
    const Color primaryColor = Color(0xFF1EC6D9);
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
                      height: mainImageSize,
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
                                    height: mainImageSize,
                                    width: mainImageSize,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              height: mainImageSize,
                                              width: mainImageSize,
                                              color: beigeColor,
                                              child: const Icon(
                                                Icons.image,
                                                size: 60,
                                                color: primaryColor,
                                              ),
                                            ),
                                  )
                                : Container(
                                    height: mainImageSize,
                                    width: mainImageSize,
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
                      children: List.generate(
                        product.images.length,
                        (index) => GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: thumbSize,
                            height: thumbSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _currentImage == index
                                    ? primaryColor
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: product.images[index].isNotEmpty
                                  ? Image.network(
                                      product.images[index],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: beigeColor,
                                                child: const Icon(
                                                  Icons.image,
                                                  size: 20,
                                                  color: primaryColor,
                                                ),
                                              ),
                                    )
                                  : Container(
                                      color: beigeColor,
                                      child: const Icon(
                                        Icons.image,
                                        size: 20,
                                        color: primaryColor,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // معلومات المنتج
              Container(
                padding: const EdgeInsets.all(20),
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
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: screenWidth * 0.048,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product.category,
                        style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.attach_money,
                          color: primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${product.price.toStringAsFixed(1)} ل.س',
                          style: TextStyle(
                            fontSize: screenWidth * 0.048,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.inventory,
                          color: Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'المتوفر: ${product.quantity}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'الوصف:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontFamily: 'Cairo',
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // زر الشراء
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
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
              // منتجات مشابهة
              if (similarProducts.isNotEmpty) ...[
                const SizedBox(height: 36),
                Text(
                  'منتجات مشابهة',
                  style: TextStyle(
                    fontSize: screenWidth * 0.048,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: similarCardWidth * 1.25,
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
                          width: similarCardWidth,
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
                                        height: similarImageHeight,
                                        width: similarCardWidth,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  height: similarImageHeight,
                                                  width: similarCardWidth,
                                                  color: beigeColor,
                                                  child: const Icon(
                                                    Icons.image,
                                                    size: 30,
                                                    color: primaryColor,
                                                  ),
                                                ),
                                      )
                                    : Container(
                                        height: similarImageHeight,
                                        width: similarCardWidth,
                                        color: beigeColor,
                                        child: const Icon(
                                          Icons.image,
                                          size: 30,
                                          color: primaryColor,
                                        ),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        fontFamily: 'Cairo',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${p.price.toStringAsFixed(1)} ل.س',
                                      style: const TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                  ],
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
