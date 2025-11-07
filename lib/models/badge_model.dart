import 'package:flutter/material.dart';

enum BadgeType {
  share,
  like,
  download,
  likes,
  shares,
  special,
}

class Badge {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int requirement;
  final BadgeType type;
  final int requiredLikes;
  final int requiredShares;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.requirement,
    required this.type,
    this.requiredLikes = 0,
    this.requiredShares = 0,
  });
}

class UserBadge {
  final String userEmail;
  final String badgeId;
  final DateTime earnedAt;

  UserBadge({
    required this.userEmail,
    required this.badgeId,
    required this.earnedAt,
  });
}