import 'package:flutter/material.dart';

enum GameCardType { steam, psn, xbox, nintendo, other, all }

class GameCard {
  final String id;
  final String name;
  final double price;
  final double value;
  final GameCardType type;
  final String description;
  final String imageUrl;
  final bool isActive;

  GameCard({
    required this.id,
    required this.name,
    required this.price,
    required this.value,
    required this.type,
    required this.description,
    required this.imageUrl,
    this.isActive = true,
  });

  // بيانات وهمية للعرض (سيتم استبدالها بقاعدة البيانات لاحقاً)
  static List<GameCard> get mockCards => [
        // Steam cards
        GameCard(
          id: 'steam_50',
          name: 'Steam',
          price: 52.50,
          value: 50.0,
          type: GameCardType.steam,
          description: 'Steam Gift Card - 50\$',
          imageUrl: 'assets/steam_icon.png',
        ),
        GameCard(
          id: 'steam_100',
          name: 'Steam',
          price: 105.00,
          value: 100.0,
          type: GameCardType.steam,
          description: 'Steam Gift Card - 100\$',
          imageUrl: 'assets/steam_icon.png',
        ),
        GameCard(
          id: 'steam_200',
          name: 'Steam',
          price: 210.00,
          value: 200.0,
          type: GameCardType.steam,
          description: 'Steam Gift Card - 200\$',
          imageUrl: 'assets/steam_icon.png',
        ),

        // PlayStation Network cards
        GameCard(
          id: 'psn_50',
          name: 'PlayStation Network',
          price: 52.00,
          value: 50.0,
          type: GameCardType.psn,
          description: 'PSN Gift Card - 50\$',
          imageUrl: 'assets/psn_icon.png',
        ),
        GameCard(
          id: 'psn_100',
          name: 'PlayStation Network',
          price: 104.00,
          value: 100.0,
          type: GameCardType.psn,
          description: 'PSN Gift Card - 100\$',
          imageUrl: 'assets/psn_icon.png',
        ),
        GameCard(
          id: 'psn_200',
          name: 'PlayStation Network',
          price: 208.00,
          value: 200.0,
          type: GameCardType.psn,
          description: 'PSN Gift Card - 200\$',
          imageUrl: 'assets/psn_icon.png',
        ),

        // Xbox cards
        GameCard(
          id: 'xbox_50',
          name: 'Xbox',
          price: 53.00,
          value: 50.0,
          type: GameCardType.xbox,
          description: 'Xbox Gift Card - 50\$',
          imageUrl: 'assets/xbox_icon.png',
        ),
        GameCard(
          id: 'xbox_100',
          name: 'Xbox',
          price: 106.00,
          value: 100.0,
          type: GameCardType.xbox,
          description: 'Xbox Gift Card - 100\$',
          imageUrl: 'assets/xbox_icon.png',
        ),
        GameCard(
          id: 'xbox_200',
          name: 'Xbox',
          price: 212.00,
          value: 200.0,
          type: GameCardType.xbox,
          description: 'Xbox Gift Card - 200\$',
          imageUrl: 'assets/xbox_icon.png',
        ),

        // Nintendo cards
        GameCard(
          id: 'nintendo_50',
          name: 'Nintendo',
          price: 54.00,
          value: 50.0,
          type: GameCardType.nintendo,
          description: 'Nintendo eShop Card - 50\$',
          imageUrl: 'assets/nintendo_icon.png',
        ),
        GameCard(
          id: 'nintendo_100',
          name: 'Nintendo',
          price: 108.00,
          value: 100.0,
          type: GameCardType.nintendo,
          description: 'Nintendo eShop Card - 100\$',
          imageUrl: 'assets/nintendo_icon.png',
        ),

        // Other cards - Google Play
        GameCard(
          id: 'google_play_50',
          name: 'Google Play',
          price: 52.50,
          value: 50.0,
          type: GameCardType.other,
          description: 'Google Play Gift Card - 50\$',
          imageUrl: 'assets/google_play_icon.png',
        ),
        GameCard(
          id: 'google_play_100',
          name: 'Google Play',
          price: 105.00,
          value: 100.0,
          type: GameCardType.other,
          description: 'Google Play Gift Card - 100\$',
          imageUrl: 'assets/google_play_icon.png',
        ),

        // Other cards - App Store
        GameCard(
          id: 'app_store_50',
          name: 'App Store',
          price: 53.00,
          value: 50.0,
          type: GameCardType.other,
          description: 'App Store Gift Card - 50\$',
          imageUrl: 'assets/app_store_icon.png',
        ),
        GameCard(
          id: 'app_store_100',
          name: 'App Store',
          price: 106.00,
          value: 100.0,
          type: GameCardType.other,
          description: 'App Store Gift Card - 100\$',
          imageUrl: 'assets/app_store_icon.png',
        ),
      ];

  // الحصول على الكروت حسب النوع
  static List<GameCard> getCardsByType(GameCardType type) {
    if (type == GameCardType.all) {
      return mockCards;
    }
    return mockCards.where((card) => card.type == type).toList();
  }

  // الحصول على اسم النوع بالعربية
  String get typeName {
    switch (type) {
      case GameCardType.steam:
        return 'Steam';
      case GameCardType.psn:
        return 'PlayStation Network';
      case GameCardType.xbox:
        return 'Xbox';
      case GameCardType.nintendo:
        return 'Nintendo';
      case GameCardType.other:
        return name; // استخدام اسم الكارت المحدد في البيانات
      case GameCardType.all:
        return 'الكل';
    }
  }

  // الحصول على أيقونة النوع
  IconData get typeIcon {
    switch (type) {
      case GameCardType.steam:
        return Icons.games;
      case GameCardType.psn:
        return Icons.gamepad;
      case GameCardType.xbox:
        return Icons.sports_esports;
      case GameCardType.nintendo:
        return Icons.videogame_asset;
      case GameCardType.other:
        return Icons.card_giftcard;
      case GameCardType.all:
        return Icons.all_inclusive;
    }
  }
} 