import 'package:flutter/material.dart';
import 'mobile_package_model.dart';
import 'orders_screen.dart';
import 'product_model.dart';

class MobileCreditScreen extends StatefulWidget {
  const MobileCreditScreen({super.key});

  @override
  State<MobileCreditScreen> createState() => _MobileCreditScreenState();
}

class _MobileCreditScreenState extends State<MobileCreditScreen> {
  MobileOperator _selectedOperator = MobileOperator.all;

  // ألوان التطبيق
  static const Color primaryColor = Color(0xFF1EC6D9);
  static const Color backgroundColor = Color(0xFFF7F7F7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(child: _buildPackagesList()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: primaryColor,
      elevation: 0,
      centerTitle: true,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.phone_android,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'تحويل رصيد الجوال',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.arrow_forward, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: _buildFilterTab(MobileOperator.other, 'أخرى')),
          const SizedBox(width: 8),
          Expanded(child: _buildFilterTab(MobileOperator.mtn, 'MTN')),
          const SizedBox(width: 8),
          Expanded(child: _buildFilterTab(MobileOperator.syriatel, 'SyriaTel')),
          const SizedBox(width: 8),
          Expanded(child: _buildFilterTab(MobileOperator.all, 'الكل')),
        ],
      ),
    );
  }

  Widget _buildFilterTab(MobileOperator operator, String label) {
    final isSelected = _selectedOperator == operator;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOperator = operator;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
              const SizedBox(height: 2),
              const Icon(Icons.check, color: Colors.white, size: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPackagesList() {
    final packages = MobilePackage.getPackagesByOperator(_selectedOperator);

    if (packages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_android_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'لا توجد باقات متاحة',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final package = packages[index];
        return _buildPackageCard(package);
      },
    );
  }

  Widget _buildPackageCard(MobilePackage package) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // الجانب الأيسر - السعر وزر الإضافة
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${package.price.toStringAsFixed(2)} ل.س',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showPackageDetails(package),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'إضافة لطلباتي',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // الجانب الأيمن - معلومات الباقة
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.operatorName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  package.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  package.operatorName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: primaryColor,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          // الأيقونة
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(package.operatorIcon, color: primaryColor, size: 24),
          ),
        ],
      ),
    );
  }

  void _showPackageDetails(MobilePackage package) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان الباقة
              Text(
                'تفاصيل باقة ${package.operatorName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 20),
              // تفاصيل الباقة
              _buildDetailRow(
                'قيمة الباقة:',
                '${package.value.toInt()} ليرة سورية',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                'السعر:',
                '${package.price.toStringAsFixed(2)} ل.س',
              ),
              const SizedBox(height: 12),
              _buildDetailRow('الشركة:', package.operatorName),
              const Spacer(),
              // أزرار الإجراءات
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _addToOrders(package);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'إضافة لطلباتي',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  void _addToOrders(MobilePackage package) {
    // إنشاء منتج من الباقة لإضافته إلى قائمة الطلبات
    final product = Product(
      name: 'باقة ${package.operatorName} - ${package.value.toInt()} ليرة',
      images: [package.imageUrl],
      price: package.price,
      quantity: 1,
      category: 'تحويل رصيد',
      description: '${package.description} - ${package.operatorName}',
    );

    // التحقق من أن المنتج غير موجود بالفعل في القائمة
    if (!OrdersScreen.pendingProducts.contains(product)) {
      setState(() {
        OrdersScreen.pendingProducts.add(product);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إضافة باقة ${package.operatorName} إلى قائمة الطلب',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الباقة موجودة بالفعل في قائمة الطلب'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
