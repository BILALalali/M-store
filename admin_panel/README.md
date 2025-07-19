# Admin Panel

لوحة تحكم المشرفين لتطبيق M-Store - تطبيق Flutter Web.

## 🏗️ الهيكل المعماري

```
lib/
├── core/                 # الكود الأساسي
│   ├── constants/        # الثوابت
│   ├── theme/           # ثيم التطبيق
│   ├── utils/           # الأدوات المساعدة
│   └── config/          # الإعدادات
├── data/                # طبقة البيانات
│   ├── models/          # نماذج البيانات
│   ├── repositories/    # مستودعات البيانات
│   └── datasources/     # مصادر البيانات
├── domain/              # طبقة الدومين
│   ├── entities/        # الكيانات الأساسية
│   ├── usecases/        # حالات الاستخدام
│   └── interfaces/      # الواجهات
└── presentation/        # الواجهات
    ├── screens/         # الشاشات
    ├── widgets/         # المكونات
    └── providers/       # إدارة الحالة
```

## 🚀 التقنيات

- **Framework**: Flutter Web
- **Architecture**: Clean Architecture
- **State Management**: Provider/Riverpod
- **Backend**: Supabase
- **UI**: Material Design 3

