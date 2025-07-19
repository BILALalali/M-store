# M-Store Project

مشروع متجر إلكتروني شامل يتكون من تطبيقين:

## 📱 التطبيقات

### 1. User App (`user_app/`)
تطبيق المستخدمين النهائيين - تطبيق Flutter للهواتف المحمولة
- **المنصة**: iOS, Android
- **الوظائف**: تصفح المنتجات، الطلبات، الملف الشخصي

### 2. Admin Panel (`admin_panel/`)
لوحة تحكم المشرفين - تطبيق Flutter Web
- **المنصة**: Web
- **الوظائف**: إدارة المنتجات، الطلبات، المستخدمين، التقارير

## 🏗️ الهيكل المعماري

```
m_store/
├── user_app/           # تطبيق المستخدمين
│   ├── lib/
│   │   ├── core/       # الكود الأساسي
│   │   ├── data/       # طبقة البيانات
│   │   ├── domain/     # طبقة الدومين
│   │   └── presentation/ # الواجهات
│   └── pubspec.yaml
├── admin_panel/        # لوحة التحكم
│   ├── lib/
│   │   ├── core/       # الكود الأساسي
│   │   ├── data/       # طبقة البيانات
│   │   ├── domain/     # طبقة الدومين
│   │   └── presentation/ # الواجهات
│   └── pubspec.yaml
└── shared/             # المكتبة المشتركة
    ├── lib/
    │   ├── services/   # الخدمات المشتركة
    │   └── shared.dart
    └── pubspec.yaml
```

## 🚀 التقنيات المستخدمة

- **Frontend**: Flutter (Dart)
- **Backend**: Supabase
- **Database**: PostgreSQL
- **Authentication**: Supabase Auth
- **Storage**: Supabase Storage
- **State Management**: Provider/Riverpod
- **Architecture**: Clean Architecture
