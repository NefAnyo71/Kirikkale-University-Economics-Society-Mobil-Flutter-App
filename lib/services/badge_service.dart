import 'package:flutter/material.dart' hide Badge;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/badge_model.dart';

class BadgeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mevcut rozetler
  static final List<Badge> _badges = [
    Badge(
      id: 'first_share',
      name: 'İlk Paylaşım',
      description: 'İlk notunu paylaştı',
      icon: Icons.share,
      color: Colors.blue,
      requirement: 1,
      type: BadgeType.shares,
      requiredShares: 1,
    ),
    Badge(
      id: 'active_sharer',
      name: 'Aktif Paylaşımcı',
      description: '5 not paylaştı',
      icon: Icons.star,
      color: Colors.orange,
      requirement: 5,
      type: BadgeType.shares,
      requiredShares: 5,
    ),
    Badge(
      id: 'super_sharer',
      name: 'Süper Paylaşımcı',
      description: '10 not paylaştı',
      icon: Icons.stars,
      color: Colors.purple,
      requirement: 10,
      type: BadgeType.shares,
      requiredShares: 10,
    ),
    Badge(
      id: 'liked_content',
      name: 'Beğenilen İçerik',
      description: '50 beğeni aldı',
      icon: Icons.thumb_up,
      color: Colors.green,
      requirement: 50,
      type: BadgeType.likes,
      requiredLikes: 50,
    ),
    Badge(
      id: 'popular_creator',
      name: 'Popüler İçerik Üreticisi',
      description: '100 beğeni aldı',
      icon: Icons.favorite,
      color: Colors.red,
      requirement: 100,
      type: BadgeType.likes,
      requiredLikes: 100,
    ),
  ];

  // Kullanıcının rozetlerini getir
  static Future<List<UserBadge>> getUserBadges(String userEmail) async {
    try {
      final snapshot = await _firestore
          .collection('user_badges')
          .where('userEmail', isEqualTo: userEmail)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserBadge(
          userEmail: data['userEmail'],
          badgeId: data['badgeId'],
          earnedAt: data['earnedAt']?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('Kullanıcı rozetleri alınırken hata: $e');
      return [];
    }
  }

  // Rozet ID'sine göre rozet bilgisini getir
  static Badge? getBadgeById(String badgeId) {
    try {
      return _badges.firstWhere((badge) => badge.id == badgeId);
    } catch (e) {
      return null;
    }
  }

  // Tüm rozetleri getir
  static List<Badge> getAllBadges() {
    return _badges;
  }

  // Mevcut rozetleri getir (alias)
  static List<Badge> get availableBadges => _badges;

  // Kullanıcının rozet kazanıp kazanmadığını kontrol et ve ver
  static Future<void> checkAndAwardBadges(String userEmail) async {
    try {
      // Kullanıcının mevcut rozetlerini al
      final userBadges = await getUserBadges(userEmail);
      final earnedBadgeIds = userBadges.map((ub) => ub.badgeId).toSet();

      // Kullanıcının istatistiklerini al
      final stats = await _getUserStats(userEmail);

      // Her rozet için kontrol yap
      for (final badge in _badges) {
        if (earnedBadgeIds.contains(badge.id)) continue; // Zaten kazanılmış

        bool shouldAward = false;

        switch (badge.type) {
          case BadgeType.share:
          case BadgeType.shares:
            shouldAward = (stats['totalShares'] ?? 0) >= badge.requirement;
            break;
          case BadgeType.like:
          case BadgeType.likes:
            shouldAward = (stats['totalLikes'] ?? 0) >= badge.requirement;
            break;
          case BadgeType.download:
            shouldAward = (stats['totalDownloads'] ?? 0) >= badge.requirement;
            break;
          case BadgeType.special:
            // Özel rozetler için ayrı kontrol
            break;
        }

        if (shouldAward) {
          await _awardBadge(userEmail, badge.id);
        }
      }
    } catch (e) {
      print('Rozet kontrolü yapılırken hata: $e');
    }
  }

  // Kullanıcının istatistiklerini al (public method)
  static Future<Map<String, int>> getUserStats(String userEmail) async {
    return await _getUserStats(userEmail);
  }

  // Kullanıcının istatistiklerini al (private method)
  static Future<Map<String, int>> _getUserStats(String userEmail) async {
    try {
      // Paylaşım sayısı
      final shareCount = await _firestore
          .collection('ders_notlari')
          .where('paylasan_kullanici_email', isEqualTo: userEmail)
          .get();

      // Toplam beğeni sayısı
      int totalLikes = 0;
      for (final doc in shareCount.docs) {
        final data = doc.data();
        totalLikes += (data['likes'] ?? 0) as int;
      }

      // Kredi bilgilerinden indirme sayısı
      final creditDoc = await _firestore
          .collection('user_credits')
          .doc(userEmail)
          .get();

      int totalDownloads = 0;
      if (creditDoc.exists) {
        final creditData = creditDoc.data() as Map<String, dynamic>;
        totalDownloads = creditData['totalDownloads'] ?? 0;
      }

      return {
        'totalShares': shareCount.docs.length,
        'totalLikes': totalLikes,
        'totalDownloads': totalDownloads,
      };
    } catch (e) {
      print('Kullanıcı istatistikleri alınırken hata: $e');
      return {
        'totalShares': 0,
        'totalLikes': 0,
        'totalDownloads': 0,
      };
    }
  }

  // Rozet ver
  static Future<void> _awardBadge(String userEmail, String badgeId) async {
    try {
      await _firestore.collection('user_badges').add({
        'userEmail': userEmail,
        'badgeId': badgeId,
        'earnedAt': FieldValue.serverTimestamp(),
      });

      print('Rozet verildi: $badgeId -> $userEmail');
    } catch (e) {
      print('Rozet verilirken hata: $e');
    }
  }
}