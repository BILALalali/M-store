import '../models/game_card.dart';
import 'supabase_service.dart';

class GameCardsService {
  static const String _cardsTable = 'game_cards';
  static const String _providersTable = 'game_card_providers';

  // الحصول على جميع البطاقات
  static Future<List<GameCard>> getAllCards() async {
    try {
      final client = SupabaseService().client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      print('جلب جميع بطاقات الألعاب من جدول: $_cardsTable');

      final response = await client
          .from(_cardsTable)
          .select('*')
          .order('sort_order')
          .order('card_value');

      print('تم جلب ${response.length} بطاقة');

      return response.map((row) => GameCard.fromMap(row)).toList();
    } catch (e) {
      print('خطأ في جلب بطاقات الألعاب: $e');
      rethrow;
    }
  }

  // الحصول على البطاقات النشطة فقط
  static Future<List<GameCard>> getActiveCards() async {
    try {
      final client = SupabaseService().client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      final response = await client
          .from(_cardsTable)
          .select('*')
          .eq('is_active', true)
          .order('sort_order')
          .order('card_value');

      return response.map((row) => GameCard.fromMap(row)).toList();
    } catch (e) {
      print('خطأ في جلب البطاقات النشطة: $e');
      rethrow;
    }
  }

  // الحصول على البطاقات حسب مقدم الخدمة
  static Future<List<GameCard>> getCardsByProvider(int providerId) async {
    try {
      final client = SupabaseService().client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      final response = await client
          .from(_cardsTable)
          .select('*')
          .eq('provider_id', providerId)
          .order('sort_order')
          .order('card_value');

      return response.map((row) => GameCard.fromMap(row)).toList();
    } catch (e) {
      print('خطأ في جلب البطاقات حسب مقدم الخدمة: $e');
      rethrow;
    }
  }

  // إضافة بطاقة جديدة
  static Future<GameCard> addCard(GameCard card) async {
    try {
      final supabaseService = SupabaseService();
      final client = supabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      print('إضافة بطاقة جديدة: ${card.cardName}');

      final cardData = card.toMap();
      cardData.remove('id'); // إزالة ID للإنشاء
      cardData['created_at'] = DateTime.now().toIso8601String();

      final response = await client
          .from(_cardsTable)
          .insert(cardData)
          .select()
          .single();

      print('تم إضافة البطاقة بنجاح: $response');
      return GameCard.fromMap(response);
    } catch (e) {
      print('خطأ في إضافة البطاقة: $e');
      rethrow;
    }
  }

  // تحديث بطاقة موجودة
  static Future<GameCard> updateCard(GameCard card) async {
    try {
      final supabaseService = SupabaseService();
      final client = supabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      if (card.id == null) {
        throw Exception('معرف البطاقة مطلوب للتحديث');
      }

      print('تحديث البطاقة: ${card.cardName}');

      final cardData = card.toMap();
      cardData.remove('created_at'); // عدم تحديث تاريخ الإنشاء

      final response = await client
          .from(_cardsTable)
          .update(cardData)
          .eq('id', card.id!)
          .select()
          .single();

      print('تم تحديث البطاقة بنجاح: $response');
      return GameCard.fromMap(response);
    } catch (e) {
      print('خطأ في تحديث البطاقة: $e');
      rethrow;
    }
  }

  // حذف بطاقة
  static Future<bool> deleteCard(int cardId) async {
    try {
      final supabaseService = SupabaseService();
      final client = supabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      print('حذف البطاقة: $cardId');

      await client.from(_cardsTable).delete().eq('id', cardId);

      print('تم حذف البطاقة بنجاح');
      return true;
    } catch (e) {
      print('خطأ في حذف البطاقة: $e');
      rethrow;
    }
  }

  // تغيير حالة البطاقة (نشط/غير نشط)
  static Future<bool> toggleCardStatus(int cardId, bool isActive) async {
    try {
      final supabaseService = SupabaseService();
      final client = supabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      print('تغيير حالة البطاقة $cardId إلى: $isActive');

      await client
          .from(_cardsTable)
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', cardId);

      print('تم تغيير حالة البطاقة بنجاح');
      return true;
    } catch (e) {
      print('خطأ في تغيير حالة البطاقة: $e');
      rethrow;
    }
  }

  // البحث في البطاقات
  static Future<List<GameCard>> searchCards(String query) async {
    try {
      final client = SupabaseService().client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      print('البحث في البطاقات: $query');

      final response = await client
          .from(_cardsTable)
          .select('*')
          .or(
            'card_name.ilike.%$query%,description_ar.ilike.%$query%,description_en.ilike.%$query%',
          )
          .order('sort_order')
          .order('card_value');

      return response.map((row) => GameCard.fromMap(row)).toList();
    } catch (e) {
      print('خطأ في البحث في البطاقات: $e');
      rethrow;
    }
  }

  // الحصول على جميع مقدمي الخدمة
  static Future<List<GameCardProvider>> getAllProviders() async {
    try {
      final client = SupabaseService().client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      print('جلب جميع مقدمي خدمة بطاقات الألعاب من جدول: $_providersTable');

      final response = await client
          .from(_providersTable)
          .select('*')
          .order('name');

      print('تم جلب ${response.length} مقدم خدمة');

      return response.map((row) => GameCardProvider.fromMap(row)).toList();
    } catch (e) {
      print('خطأ في جلب مقدمي الخدمة: $e');
      rethrow;
    }
  }

  // الحصول على مقدمي الخدمة النشطين فقط
  static Future<List<GameCardProvider>> getActiveProviders() async {
    try {
      final client = SupabaseService().client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      final response = await client
          .from(_providersTable)
          .select('*')
          .eq('is_active', true)
          .order('name');

      return response.map((row) => GameCardProvider.fromMap(row)).toList();
    } catch (e) {
      print('خطأ في جلب مقدمي الخدمة النشطين: $e');
      rethrow;
    }
  }

  // إضافة مقدم خدمة جديد
  static Future<GameCardProvider> addProvider(GameCardProvider provider) async {
    try {
      final supabaseService = SupabaseService();
      final client = supabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      print('إضافة مقدم خدمة جديد: ${provider.name}');

      final providerData = provider.toMap();
      providerData.remove('id'); // إزالة ID للإنشاء
      providerData['created_at'] = DateTime.now().toIso8601String();

      final response = await client
          .from(_providersTable)
          .insert(providerData)
          .select()
          .single();

      print('تم إضافة مقدم الخدمة بنجاح: $response');
      return GameCardProvider.fromMap(response);
    } catch (e) {
      print('خطأ في إضافة مقدم الخدمة: $e');
      rethrow;
    }
  }

  // تحديث مقدم خدمة موجود
  static Future<GameCardProvider> updateProvider(
    GameCardProvider provider,
  ) async {
    try {
      final supabaseService = SupabaseService();
      final client = supabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      if (provider.id == null) {
        throw Exception('معرف مقدم الخدمة مطلوب للتحديث');
      }

      print('تحديث مقدم الخدمة: ${provider.name}');

      final providerData = provider.toMap();
      providerData.remove('created_at'); // عدم تحديث تاريخ الإنشاء

      final response = await client
          .from(_providersTable)
          .update(providerData)
          .eq('id', provider.id!)
          .select()
          .single();

      print('تم تحديث مقدم الخدمة بنجاح: $response');
      return GameCardProvider.fromMap(response);
    } catch (e) {
      print('خطأ في تحديث مقدم الخدمة: $e');
      rethrow;
    }
  }

  // حذف مقدم خدمة
  static Future<bool> deleteProvider(int providerId) async {
    try {
      final supabaseService = SupabaseService();
      final client = supabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      print('حذف مقدم الخدمة: $providerId');

      // التحقق من وجود بطاقات مرتبطة بمقدم الخدمة
      final cards = await getCardsByProvider(providerId);
      if (cards.isNotEmpty) {
        throw Exception('لا يمكن حذف مقدم الخدمة لأنه يحتوي على بطاقات مرتبطة');
      }

      await client.from(_providersTable).delete().eq('id', providerId);

      print('تم حذف مقدم الخدمة بنجاح');
      return true;
    } catch (e) {
      print('خطأ في حذف مقدم الخدمة: $e');
      rethrow;
    }
  }

  // تغيير حالة مقدم الخدمة (نشط/غير نشط)
  static Future<bool> toggleProviderStatus(
    int providerId,
    bool isActive,
  ) async {
    try {
      final supabaseService = SupabaseService();
      final client = supabaseService.client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      print('تغيير حالة مقدم الخدمة $providerId إلى: $isActive');

      await client
          .from(_providersTable)
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', providerId);

      print('تم تغيير حالة مقدم الخدمة بنجاح');
      return true;
    } catch (e) {
      print('خطأ في تغيير حالة مقدم الخدمة: $e');
      rethrow;
    }
  }

  // الحصول على إحصائيات البطاقات
  static Future<Map<String, dynamic>> getCardsStats() async {
    try {
      final client = SupabaseService().client;
      if (client == null) {
        throw Exception('Supabase غير متصل');
      }

      // جلب عدد البطاقات الإجمالي
      final totalCards = await client.from(_cardsTable).select('id');

      // جلب عدد البطاقات النشطة
      final activeCards = await client
          .from(_cardsTable)
          .select('id')
          .eq('is_active', true);

      // جلب عدد مقدمي الخدمة
      final totalProviders = await client.from(_providersTable).select('id');

      // جلب عدد مقدمي الخدمة النشطين
      final activeProviders = await client
          .from(_providersTable)
          .select('id')
          .eq('is_active', true);

      return {
        'total_cards': totalCards.length,
        'active_cards': activeCards.length,
        'total_providers': totalProviders.length,
        'active_providers': activeProviders.length,
      };
    } catch (e) {
      print('خطأ في جلب إحصائيات البطاقات: $e');
      return {
        'total_cards': 0,
        'active_cards': 0,
        'total_providers': 0,
        'active_providers': 0,
      };
    }
  }
}
