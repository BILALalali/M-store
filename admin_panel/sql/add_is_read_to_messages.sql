-- إضافة حقل is_read إلى جدولي order_messages و wholesale_messages
-- نفس آلية support_messages بالضبط: المشرف يقرأ رسائل المستخدمين

-- إضافة حقل is_read إلى جدول order_messages
ALTER TABLE order_messages 
ADD COLUMN IF NOT EXISTS is_read BOOLEAN NOT NULL DEFAULT FALSE;

-- إضافة تعليق على العمود (نفس منطق support_messages)
COMMENT ON COLUMN order_messages.is_read IS 'حالة قراءة الرسالة: FALSE = غير مقروءة، TRUE = مقروءة (المشرف يقرأ رسائل المستخدمين)';

-- إضافة حقل is_read إلى جدول wholesale_messages
ALTER TABLE wholesale_messages 
ADD COLUMN IF NOT EXISTS is_read BOOLEAN NOT NULL DEFAULT FALSE;

-- إضافة تعليق على العمود (نفس منطق support_messages)
COMMENT ON COLUMN wholesale_messages.is_read IS 'حالة قراءة الرسالة: FALSE = غير مقروءة، TRUE = مقروءة (المشرف يقرأ رسائل المستخدمين)';

-- إضافة فهرس للرسائل غير المقروءة من المستخدمين (التي يقرأها المشرف)
-- نفس منطق support_messages بالضبط
CREATE INDEX IF NOT EXISTS idx_order_messages_unread_user_messages
ON order_messages(conversation_id, sender_type, is_read) 
WHERE sender_type = 'user' AND is_read = FALSE;

CREATE INDEX IF NOT EXISTS idx_wholesale_messages_unread_user_messages
ON wholesale_messages(conversation_id, sender_type, is_read) 
WHERE sender_type = 'user' AND is_read = FALSE;

-- فهرس لحساب إجمالي الرسائل غير المقروءة (مثل support_messages)
CREATE INDEX IF NOT EXISTS idx_order_messages_total_unread
ON order_messages(sender_type, is_read) 
WHERE sender_type = 'user' AND is_read = FALSE;

CREATE INDEX IF NOT EXISTS idx_wholesale_messages_total_unread
ON wholesale_messages(sender_type, is_read) 
WHERE sender_type = 'user' AND is_read = FALSE;

-- عرض النتائج للتأكد من إضافة الأعمدة
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name IN ('order_messages', 'wholesale_messages') 
AND column_name = 'is_read';
