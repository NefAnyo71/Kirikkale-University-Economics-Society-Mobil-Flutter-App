import 'package:flutter/material.dart';

class Badge {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int requiredLikes;
  final int requiredDislikes;
  final int requiredShares;
  final BadgeType type;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.requiredLikes = 0,
    this.requiredDislikes = 0,
    this.requiredShares = 0,
    required this.type,
  });
}

enum BadgeType {
  likes,
  shares,
  special,
}

class UserBadge {
  final String badgeId;
  final DateTime earnedDate;
  final String userId;

  UserBadge({
    required this.badgeId,
    required this.earnedDate,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'badgeId': badgeId,
      'earnedDate': earnedDate,
      'userId': userId,
    };
  }

  factory UserBadge.fromMap(Map<String, dynamic> map) {
    return UserBadge(
      badgeId: map['badgeId'],
      earnedDate: map['earnedDate'].toDate(),
      userId: map['userId'],
    );
  }
}