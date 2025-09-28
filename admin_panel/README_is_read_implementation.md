# تنفيذ نظام الرسائل غير المقروءة - نسخة طبق الأصل من support_messages

## 📋 آلية عمل النظام

### 🎯 **منطق support_messages المُطبق:**

- **👨‍💼 المشرف في لوحة التحكم** يقرأ رسائل **المستخدمين** (`sender_type = 'user'`) → `is_read = TRUE`
- **📝 القيمة الافتراضية:** جميع الرسائل تبدأ بـ `is_read = FALSE`
- **📊 العداد:** يحسب رسائل المستخدمين غير المقروءة فقط (`sender_type = 'user' AND is_read = false`)

### ✅ **تم تطبيق نفس منطق support_messages بالضبط:**
- نفس دوال العداد
- نفس منطق التحديث
- نفس البنية والتنظيم

---

## ملخص التحديثات

### 1. إضافة حقل is_read إلى قاعدة البيانات

تم إنشاء ملف SQL (`admin_panel/sql/add_is_read_to_messages.sql`) لإضافة حقل `is_read` إلى الجدولين:

- `order_messages`
- `wholesale_messages`

#### التحديثات المطلوبة في قاعدة البيانات:

```sql
-- تشغيل هذا السكريبت في Supabase SQL Editor:
-- admin_panel/sql/add_is_read_to_messages.sql
```

### 2. تحديث خدمة الطلبات (OrderService)

#### الملف: `admin_panel/lib/core/services/order_service.dart`

✅ **نسخة طبق الأصل من support_messages:**

#### 🔸 **الدوال المُحدثة** (نفس أسماء support_messages):
1. **`markOrderMessagesAsRead()`** - نسخة من `markMessagesAsRead()` في support_messages
2. **`_getUnreadCount()`** - نسخة من `_getUnreadCount()` في support_messages  
3. **`getTotalUnreadOrderMessagesCount()`** - نسخة من `getTotalUnreadMessagesCount()` في support_messages
4. **`getUnreadOrderThreadsCount()`** - نسخة من `getUnreadConversationsCount()` في support_messages

#### البنية المطابقة:
```dart
// دوال المشرف (نفس منطق support_messages)
markOrderMessagesAsRead(String orderId)          // تحديث رسائل المستخدمين كمقروءة
_getUnreadCount(String orderId)                  // حساب رسائل المستخدمين غير المقروءة
getTotalUnreadOrderMessagesCount()               // إجمالي الرسائل غير المقروءة
getUnreadOrderThreadsCount()                     // عدد الطلبات غير المقروءة
```

### 3. تحديث خدمة الجملة (WholesaleService)

#### الملف: `admin_panel/lib/core/services/wholesale_service.dart`

✅ **نسخة طبق الأصل من support_messages:**

#### 🔸 **الدوال المُحدثة** (نفس أسماء support_messages):
1. **`markWholesaleMessagesAsRead()`** - نسخة من `markMessagesAsRead()` في support_messages
2. **`_getUnreadCount()`** - نسخة من `_getUnreadCount()` في support_messages
3. **`getTotalUnreadWholesaleMessagesCount()`** - نسخة من `getTotalUnreadMessagesCount()` في support_messages  
4. **`getUnreadWholesaleRequestsCount()`** - نسخة من `getUnreadConversationsCount()` في support_messages

#### البنية المطابقة:
```dart
// دوال المشرف (نفس منطق support_messages)
markWholesaleMessagesAsRead(String requestId)    // تحديث رسائل المستخدمين كمقروءة
_getUnreadCount(String requestId)                // حساب رسائل المستخدمين غير المقروءة
getTotalUnreadWholesaleMessagesCount()           // إجمالي الرسائل غير المقروءة
getUnreadWholesaleRequestsCount()                // عدد طلبات الجملة غير المقروءة
```

### 4. النماذج (Models)

✅ **تم التأكد من أن النماذج تدعم حقل `is_read`:**

- `OrderMessage` - يحتوي على حقل `isRead`
- `WholesaleMessage` - يحتوي على حقل `isRead`
- `SupportMessage` - يحتوي على حقل `isRead` (للمقارنة)

### 5. خطوات التطبيق

#### للمطور:

1. **تشغيل السكريبت SQL:**
   ```sql
   -- في Supabase SQL Editor، تشغيل محتوى ملف:
   -- admin_panel/sql/add_is_read_to_messages.sql
   ```

2. **التحقق من إضافة الأعمدة:**
   ```sql
   SELECT column_name, data_type, column_default 
   FROM information_schema.columns 
   WHERE table_name IN ('order_messages', 'wholesale_messages') 
   AND column_name = 'is_read';
   ```

3. **دمج الدوال في تطبيق المستخدم:**
   - نسخ الدوال `markAdminMessagesAsReadForUser()` و `getUnreadAdminMessagesCountForUser()`
   - استخدامها في تطبيق المستخدم عند فتح المحادثات

### 6. 🎯 الاستخدام العملي (نفس support_messages)

#### 👨‍💼 في لوحة المشرف:
```dart
// === للطلبات ===
// عند فتح محادثة طلب (نفس support_messages)
await OrderService().markOrderMessagesAsRead(orderId);

// عرض إجمالي الرسائل غير المقروءة (نفس support_messages)
final totalUnread = await OrderService().getTotalUnreadOrderMessagesCount();

// عرض عدد الطلبات غير المقروءة (نفس support_messages)  
final unreadThreads = await OrderService().getUnreadOrderThreadsCount();

// === لطلبات الجملة ===
// عند فتح محادثة طلب جملة (نفس support_messages)
await WholesaleService().markWholesaleMessagesAsRead(requestId);

// عرض إجمالي الرسائل غير المقروءة (نفس support_messages)
final totalUnread = await WholesaleService().getTotalUnreadWholesaleMessagesCount();

// عرض عدد طلبات الجملة غير المقروءة (نفس support_messages)
final unreadRequests = await WholesaleService().getUnreadWholesaleRequestsCount();
```

#### 📊 **تطابق مع support_messages:**
```dart
// support_messages (المرجع)
getTotalUnreadMessagesCount()     → getTotalUnreadOrderMessagesCount()
getUnreadConversationsCount()     → getUnreadOrderThreadsCount()
markMessagesAsRead()              → markOrderMessagesAsRead()
_getUnreadCount()                 → _getUnreadCount()
```

### 7. ✅ النظام المُحدث (طبق الأصل من support_messages)

✅ **تم تطبيق نفس منطق support_messages بالضبط:**

1. **👨‍💼 المشرف يقرأ رسائل المستخدمين فقط** - نفس support_messages
2. **📊 عداد دقيق** يحسب رسائل المستخدمين غير المقروءة - نفس support_messages  
3. **⚡ أداء محسن** مع فهارس متطابقة مع support_messages
4. **🎯 منطق موحد** عبر جميع أنواع المحادثات

### 8. ملاحظات مهمة

- ⚠️ **يجب تشغيل السكريبت SQL قبل استخدام التطبيق**
- ✅ جميع الرسائل الجديدة ستكون `is_read = false` افتراضياً  
- 🎯 **النظام مخصص للمشرفين فقط** - نفس support_messages
- 🚀 النظام يعمل بنفس منطق `support_messages` تماماً

### 9. الفهارس المُحدثة (متطابقة مع support_messages)

```sql
-- للبحث عن رسائل المستخدمين غير المقروءة (نفس support_messages)
idx_order_messages_unread_user_messages
idx_wholesale_messages_unread_user_messages

-- لحساب إجمالي الرسائل غير المقروءة (نفس support_messages)
idx_order_messages_total_unread  
idx_wholesale_messages_total_unread
```

### 10. الاختبار

للتأكد من عمل النظام (نفس اختبار support_messages):

#### في لوحة المشرف:
1. فتح محادثة طلب تحتوي على رسائل من المستخدم
2. التأكد من تحديث العداد إلى صفر  
3. فحص قاعدة البيانات للتأكد من تحديث `is_read = true`
4. اختبار إجمالي العداد عبر جميع الطلبات

#### مقارنة مع support_messages:
- نفس السلوك تماماً
- نفس دوال العداد
- نفس منطق التحديث

---

✅ **الحالة: مكتمل** - نظام طبق الأصل من support_messages جاهز للتطبيق!

## 🎯 **الخلاصة:**

تم تطبيق **نفس منطق support_messages بالضبط** في:
- ✅ OrderService (نظام الطلبات)  
- ✅ WholesaleService (نظام طلبات الجملة)
- ✅ نفس أسماء الدوال ونفس المنطق
- ✅ نفس الفهارس ونفس الأداء

**النتيجة:** نظام موحد ومتسق عبر جميع أنواع المحادثات! 🚀
