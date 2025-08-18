import 'package:flutter/material.dart';

enum GameCardType { steam, psn, xbox, nintendo, other, all }

class GameCardProviderModel {
  final int id;
  final String name; // steam, psn, xbox, ...
  final String displayNameAr;
  final String displayNameEn;
  final String? logoUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  GameCardProviderModel({
    required this.id,
    required this.name,
    required this.displayNameAr,
    required this.displayNameEn,
    this.logoUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GameCardProviderModel.fromJson(Map<String, dynamic> json) {
    return GameCardProviderModel(
      id: json['id'],
      name: json['name'],
      displayNameAr: json['display_name_ar'],
      displayNameEn: json['display_name_en'],
      logoUrl: json['logo_url'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class GameCard {
  final int id;
  final int providerId;
  final String cardName;
  final double price;
  final double value;
  final String? descriptionAr;
  final String? descriptionEn;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  GameCardProviderModel? provider;

  GameCard({
    required this.id,
    required this.providerId,
    required this.cardName,
    required this.price,
    required this.value,
    this.descriptionAr,
    this.descriptionEn,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.provider,
  });

  factory GameCard.fromJson(Map<String, dynamic> json) {
    return GameCard(
      id: json['id'],
      providerId: json['provider_id'],
      cardName: json['card_name'],
      price: double.parse(json['card_price'].toString()),
      value: double.parse(json['card_value'].toString()),
      descriptionAr: json['description_ar'],
      descriptionEn: json['description_en'],
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // بيانات وهمية احتياطية
  static List<GameCard> getMockCards() => [
        GameCard(
          id: 1,
          providerId: 1,
          cardName: 'Steam',
          price: 52.50,
          value: 50,
          descriptionAr: 'Steam Gift Card - 50\$',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        GameCard(
          id: 2,
          providerId: 2,
          cardName: 'PlayStation Network',
          price: 52.00,
          value: 50,
          descriptionAr: 'PSN Gift Card - 50\$',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

  // توافق مع واجهة العرض الحالية
  String get typeName => provider?.displayNameAr ?? cardName;

  String get description =>
      descriptionAr ?? descriptionEn ?? 'قيمة الكارت: ${value.toInt()}\$';

  String get imageUrl => provider?.logoUrl ?? 'assets/gamepad_icon.png';

  IconData get typeIcon {
    final key = provider?.name.toLowerCase() ?? cardName.toLowerCase();
    if (key.contains('steam')) return Icons.games;
    if (key.contains('psn') || key.contains('playstation')) return Icons.gamepad;
    if (key.contains('xbox')) return Icons.sports_esports;
    if (key.contains('nintendo')) return Icons.videogame_asset;
    return Icons.card_giftcard;
  }
}