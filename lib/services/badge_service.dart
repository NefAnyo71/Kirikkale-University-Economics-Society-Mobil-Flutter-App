import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/badge_model.dart' as badge_model;

class BadgeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final List<badge_model.Badge> availableBadges = [
    badge_model.Badge(
      id: 'first_like',
      name: '🎯 İlk Beğeni',
      description: 'İlk beğenini aldın!',
      icon: Icons.thumb_up,
      color: Colors.green,
      requiredLikes: 1,
      type: badge_model.BadgeType.likes,
    ),
    badge_model.Badge(
      id: 'popular_note',
      name: '⭐ Popüler Not',
      description: '10 beğeni aldın!',
      icon: Icons.star,
      color: Colors.orange,
      requiredLikes: 10,
      type: badge_model.BadgeType.likes,
    ),
    badge_model.Badge(
      id: 'super_popular',
      name: '🔥 Süper Popüler',
      description: '25 beğeni aldın!',
      icon: Icons.local_fire_department,
      color: Colors.red,
      requiredLikes: 25,
      type: badge_model.BadgeType.likes,
    ),
    badge_model.Badge(
      id: 'legend',
      name: '👑 Efsane',
      description: '50 beğeni aldın!',
      icon: Icons.emoji_events,
      color: Colors.amber,
      requiredLikes: 50,
      type: badge_model.BadgeType.likes,
    ),
    badge_model.Badge(
      id: 'first_share',
      name: '📚 İlk Paylaşım',
      description: 'İlk notunu paylaştın!',
      icon: Icons.share,
      color: Colors.blue,
      requiredShares: 1,
      type: badge_model.BadgeType.shares,
    ),
    badge_model.Badge(
      id: 'active_sharer',
      name: '📖 Aktif Paylaşımcı',
      description: '5 not paylaştın!',
      icon: Icons.library_books,
      color: Colors.purple,
      requiredShares: 5,
      type: badge_model.BadgeType.shares,
    ),
    badge_model.Badge(
      id: 'note_master',
      name: '🎓 Not Ustası',
      description: '10 not paylaştın!',
      icon: Icons.school,
      color: Colors.indigo,
      requiredShares: 10,
      type: badge_model.BadgeType.shares,
    ),
  ];

  static Future<void> checkAndAwardBadges(String userEmail) async {
    try {
      final userStats = await getUserStats(userEmail);
      final currentBadges = await getUserBadges(userEmail);
      final currentBadgeIds = currentBadges.map((b) => b.badgeId).toList();

      for (badge_model.Badge badge in availableBadges) {
        if (!currentBadgeIds.contains(badge.id)) {
          bool shouldAward = false;

          switch (badge.type) {
            case badge_model.BadgeType.likes:
              shouldAward = (userStats['totalLikes'] ?? 0) >= badge.requiredLikes;
              break;
            case badge_model.BadgeType.shares:
              shouldAward = (userStats['totalShares'] ?? 0) >= badge.requiredShares;
              break;
            case badge_model.BadgeType.special:
              break;
          }

          if (shouldAward) {
            await awardBadge(userEmail, badge.id);
          }
        }
      }
    } catch (e) {
      print('Rozet kontrolü hatası: $e');
    }
  }

  static Future<Map<String, int>> getUserStats(String userEmail) async {
    try {
      final notesQuery = await _firestore
          .collection('ders_notlari')
          .where('paylasan_kullanici_email', isEqualTo: userEmail)
          .get();

      int totalLikes = 0;
      int totalShares = notesQuery.docs.length;

      for (var doc in notesQuery.docs) {
        final data = doc.data();
        totalLikes += (data['likes'] ?? 0) as int;
      }

      return {
        'totalLikes': totalLikes,
        'totalShares': totalShares,
      };
    } catch (e) {
      print('Kullanıcı istatistikleri alınırken hata: $e');
      return {'totalLikes': 0, 'totalShares': 0};
    }
  }

  static Future<void> awardBadge(String userEmail, String badgeId) async {
    try {
      await _firestore
          .collection('user_badges')
          .doc('${userEmail}_$badgeId')
          .set({
        'userId': userEmail,
        'badgeId': badgeId,
        'earnedDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Rozet verme hatası: $e');
    }
  }

  static Future<List<badge_model.UserBadge>> getUserBadges(String userEmail) async {
    try {
      final query = await _firestore
          .collection('user_badges')
          .where('userId', isEqualTo: userEmail)
          .get();

      return query.docs.map((doc) => badge_model.UserBadge.fromMap(doc.data())).toList();
    } catch (e) {
      print('Kullanıcı rozetleri alınırken hata: $e');
      return [];
    }
  }

  static badge_model.Badge? getBadgeById(String badgeId) {
    try {
      return availableBadges.firstWhere((badge) => badge.id == badgeId);
    } catch (e) {
      return null;
    }
  }
}