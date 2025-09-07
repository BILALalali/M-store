import 'package:flutter/material.dart';

class UtilScreen {
  /// تحديد نوع الشاشة بناءً على العرض
  static ScreenType getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 600) {
      return ScreenType.mobile;
    } else if (width < 900) {
      return ScreenType.tablet;
    } else if (width < 1200) {
      return ScreenType.desktop;
    } else {
      return ScreenType.largeDesktop;
    }
  }

  /// الحصول على عدد الأعمدة المناسب للشبكة
  static int getGridColumns(BuildContext context) {
    final screenType = getScreenType(context);
    
    switch (screenType) {
      case ScreenType.mobile:
        return 1;
      case ScreenType.tablet:
        return 2;
      case ScreenType.desktop:
        return 3;
      case ScreenType.largeDesktop:
        return 4;
    }
  }

  /// الحصول على المسافات المناسبة
  static double getSpacing(BuildContext context) {
    final screenType = getScreenType(context);
    
    switch (screenType) {
      case ScreenType.mobile:
        return 8.0;
      case ScreenType.tablet:
        return 12.0;
      case ScreenType.desktop:
        return 16.0;
      case ScreenType.largeDesktop:
        return 20.0;
    }
  }

  /// الحصول على حجم الخط المناسب
  static double getFontSize(BuildContext context, FontSizeType type) {
    final screenType = getScreenType(context);
    
    switch (type) {
      case FontSizeType.title:
        switch (screenType) {
          case ScreenType.mobile:
            return 16.0;
          case ScreenType.tablet:
            return 18.0;
          case ScreenType.desktop:
            return 20.0;
          case ScreenType.largeDesktop:
            return 22.0;
        }
      case FontSizeType.subtitle:
        switch (screenType) {
          case ScreenType.mobile:
            return 12.0;
          case ScreenType.tablet:
            return 14.0;
          case ScreenType.desktop:
            return 16.0;
          case ScreenType.largeDesktop:
            return 18.0;
        }
      case FontSizeType.body:
        switch (screenType) {
          case ScreenType.mobile:
            return 10.0;
          case ScreenType.tablet:
            return 12.0;
          case ScreenType.desktop:
            return 14.0;
          case ScreenType.largeDesktop:
            return 16.0;
        }
      case FontSizeType.caption:
        switch (screenType) {
          case ScreenType.mobile:
            return 8.0;
          case ScreenType.tablet:
            return 10.0;
          case ScreenType.desktop:
            return 12.0;
          case ScreenType.largeDesktop:
            return 14.0;
        }
    }
  }

  /// الحصول على الحشو المناسب
  static EdgeInsets getPadding(BuildContext context, PaddingType type) {
    final screenType = getScreenType(context);
    final basePadding = getSpacing(context);
    
    switch (type) {
      case PaddingType.small:
        return EdgeInsets.all(basePadding * 0.5);
      case PaddingType.medium:
        return EdgeInsets.all(basePadding);
      case PaddingType.large:
        return EdgeInsets.all(basePadding * 1.5);
      case PaddingType.card:
        switch (screenType) {
          case ScreenType.mobile:
            return const EdgeInsets.all(12.0);
          case ScreenType.tablet:
            return const EdgeInsets.all(16.0);
          case ScreenType.desktop:
            return const EdgeInsets.all(20.0);
          case ScreenType.largeDesktop:
            return const EdgeInsets.all(24.0);
        }
    }
  }

  /// التحقق من أن الشاشة صغيرة
  static bool isMobile(BuildContext context) {
    return getScreenType(context) == ScreenType.mobile;
  }

  /// التحقق من أن الشاشة متوسطة أو أكبر
  static bool isTabletOrLarger(BuildContext context) {
    final screenType = getScreenType(context);
    return screenType == ScreenType.tablet || 
           screenType == ScreenType.desktop || 
           screenType == ScreenType.largeDesktop;
  }

  /// الحصول على العرض المتاح للكروت
  static double getAvailableWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final screenType = getScreenType(context);
    
    switch (screenType) {
      case ScreenType.mobile:
        return width - 32; // مساحة جانبية 16px من كل جانب
      case ScreenType.tablet:
        return width - 48; // مساحة جانبية 24px من كل جانب
      case ScreenType.desktop:
        return width - 64; // مساحة جانبية 32px من كل جانب
      case ScreenType.largeDesktop:
        return width - 80; // مساحة جانبية 40px من كل جانب
    }
  }
}

enum ScreenType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

enum FontSizeType {
  title,
  subtitle,
  body,
  caption,
}

enum PaddingType {
  small,
  medium,
  large,
  card,
}
