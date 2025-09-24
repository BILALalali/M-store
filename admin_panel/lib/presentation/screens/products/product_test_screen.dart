import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ProductTestScreen extends StatelessWidget {
  const ProductTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار قسم المنتجات'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'قسم إدارة المنتجات جاهز!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يمكنك الآن إدارة المنتجات وإضافتها وحذفها',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.text.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('العودة للوحة الإدارة'),
            ),
          ],
        ),
      ),
    );
  }
}
