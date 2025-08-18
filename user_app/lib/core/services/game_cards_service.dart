import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../../presentation/screens/game_card_model.dart';

class GameCardsService {
  static const String _cardsTable = 'game_cards';
  static const String _providersTable = 'game_card_providers';

  // جلب جميع الكروت النشطة
  static Future<List<GameCard>> getAllCards() async {
    final client = SupabaseService.client;
    if (client == null) {
      print('Supabase غير متصل');
      return GameCard.getMockCards();
    }

    try {
      final response = await client
          .from(_cardsTable)
          .select('*')
          .eq('is_active', true)
          .order('sort_order')
          .order('card_value');

      if (response == null || response.isEmpty) return [];

      final List<GameCard> cards = [];
      for (final row in response) {
        final card = GameCard.fromJson(row);

        // جلب معلومات المزود
        try {
          final provider = await client
              .from(_providersTable)
              .select('*')
              .eq('id', card.providerId)
              .eq('is_active', true)
              .maybeSingle();
          if (provider != null) {
            card.provider = GameCardProviderModel.fromJson(provider);
          }
        } catch (e) {
          print('فشل جلب مزود الكارت ${card.providerId}: $e');
        }

        cards.add(card);
      }

      return cards;
    } catch (e) {
      print('خطأ في جلب الكروت: $e');
      rethrow;
    }
  }

  // جلب الكروت حسب اسم المزود (steam, psn, ...)
  static Future<List<GameCard>> getCardsByProviderName(
    String providerName,
  ) async {
    final client = SupabaseService.client;
    if (client == null) {
      print('Supabase غير متصل');
      return GameCard.getMockCards();
    }

    try {
      final provider = await client
          .from(_providersTable)
          .select('id')
          .eq('name', providerName)
          .eq('is_active', true)
          .maybeSingle();

      if (provider == null) return [];

      final response = await client
          .from(_cardsTable)
          .select('*')
          .eq('is_active', true)
          .eq('provider_id', provider['id'])
          .order('sort_order')
          .order('card_value');

      if (response == null || response.isEmpty) return [];

      final List<GameCard> cards = [];
      for (final row in response) {
        final card = GameCard.fromJson(row);
        try {
          final providerData = await client
              .from(_providersTable)
              .select('*')
              .eq('id', card.providerId)
              .maybeSingle();
          if (providerData != null) {
            card.provider = GameCardProviderModel.fromJson(providerData);
          }
        } catch (_) {}
        cards.add(card);
      }
      return cards;
    } catch (e) {
      print('خطأ في جلب الكروت حسب المزود: $e');
      rethrow;
    }
  }
}
