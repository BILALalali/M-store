import 'package:flutter/material.dart';
import 'dart:io';

/// خدمة مساعدة للتعامل مع الصور
class ImageService {
  /// عرض صورة مع معالجة الأخطاء
  static Widget buildNetworkImage({
    required String imageUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: const Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                  size: 32,
                ),
              );
        },
      ),
    );
  }

  /// عرض صورة محلية مع معالجة الأخطاء
  static Widget buildFileImage({
    required File imageFile,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? errorWidget,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.file(
        imageFile,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: const Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                  size: 32,
                ),
              );
        },
      ),
    );
  }

  /// عرض صورة ذكية (شبكة أو محلية)
  static Widget buildSmartImage({
    required String imagePath,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (imagePath.startsWith('file://') || imagePath.startsWith('/')) {
      try {
        final file = File(imagePath.replaceFirst('file://', ''));
        if (file.existsSync()) {
          return buildFileImage(
            imageFile: file,
            width: width,
            height: height,
            fit: fit,
            borderRadius: borderRadius,
            errorWidget: errorWidget,
          );
        }
      } catch (e) {
        // إذا فشل في قراءة الملف، نعرض صورة الشبكة
      }
    }

    // إذا لم تكن صورة محلية أو فشلت في قراءتها، نعرض صورة الشبكة
    return buildNetworkImage(
      imageUrl: imagePath,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }

  /// التحقق من صحة رابط الصورة
  static bool isValidImageUrl(String url) {
    if (url.isEmpty) return false;

    // التحقق من أن الرابط يبدأ بـ http أو https
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return false;
    }

    // التحقق من أن الرابط يحتوي على امتداد صورة
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
    final lowerUrl = url.toLowerCase();
    return imageExtensions.any((ext) => lowerUrl.contains(ext));
  }

  /// الحصول على صورة افتراضية
  static Widget getDefaultImage({
    required double width,
    required double height,
    Color? backgroundColor,
    Color? iconColor,
    double? iconSize,
  }) {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Colors.grey[200],
      child: Icon(
        Icons.image,
        color: iconColor ?? Colors.grey,
        size: iconSize ?? 32,
      ),
    );
  }
}
