import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/badge_model.dart' as badge_model;
import 'services/badge_service.dart';

class UserBadgesPage extends StatefulWidget {
  const UserBadgesPage({Key? key}) : super(key: key);

  @override
  State<UserBadgesPage> createState() => _UserBadgesPageState();
}

class _UserBadgesPageState extends State<UserBadgesPage> {
  List<badge_model.UserBadge> userBadges = [];
  Map<String, int> userStats = {};
  String userEmail = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    userEmail = prefs.getString('email') ?? '';
    
    if (userEmail.isNotEmpty) {
      await _loadBadgesAndStats();
    }
    
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadBadgesAndStats() async {
    userBadges = await BadgeService.getUserBadges(userEmail);
    userStats = await BadgeService.getUserStats(userEmail);
    await BadgeService.checkAndAwardBadges(userEmail);
    userBadges = await BadgeService.getUserBadges(userEmail);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rozetlerim', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCard(),
                  const SizedBox(height: 20),
                  _buildEarnedBadges(),
                  const SizedBox(height: 20),
                  _buildAvailableBadges(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 İstatistiklerim',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('👍', 'Toplam Beğeni', userStats['totalLikes'] ?? 0),
                _buildStatItem('📚', 'Paylaştığım Not', userStats['totalShares'] ?? 0),
                _buildStatItem('🏆', 'Kazandığım Rozet', userBadges.length),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String emoji, String label, int value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildEarnedBadges() {
    final earnedBadgeIds = userBadges.map((b) => b.badgeId).toList();
    final earnedBadges = BadgeService.availableBadges
        .where((badge) => earnedBadgeIds.contains(badge.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏆 Kazandığım Rozetler',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        earnedBadges.isEmpty
            ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Henüz rozet kazanmadınız.\nDers notu paylaşarak rozet kazanabilirsiniz!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: earnedBadges.length,
                itemBuilder: (context, index) {
                  return _buildBadgeCard(earnedBadges[index], true);
                },
              ),
      ],
    );
  }

  Widget _buildAvailableBadges() {
    final earnedBadgeIds = userBadges.map((b) => b.badgeId).toList();
    final availableBadges = BadgeService.availableBadges
        .where((badge) => !earnedBadgeIds.contains(badge.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🎯 Kazanılabilir Rozetler',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: availableBadges.length,
          itemBuilder: (context, index) {
            return _buildBadgeCard(availableBadges[index], false);
          },
        ),
      ],
    );
  }

  Widget _buildBadgeCard(badge_model.Badge badge, bool isEarned) {
    return Card(
      elevation: isEarned ? 6 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isEarned
              ? LinearGradient(
                  colors: [badge.color.withOpacity(0.1), badge.color.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                badge.icon,
                size: 32,
                color: isEarned ? badge.color : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                badge.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isEarned ? badge.color : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                badge.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isEarned ? Colors.black87 : Colors.grey,
                ),
              ),
              if (!isEarned) ...[
                const SizedBox(height: 4),
                _buildProgress(badge),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(badge_model.Badge badge) {
    int current = 0;
    int required = 0;

    switch (badge.type) {
      case badge_model.BadgeType.likes:
        current = userStats['totalLikes'] ?? 0;
        required = badge.requiredLikes;
        break;
      case badge_model.BadgeType.shares:
        current = userStats['totalShares'] ?? 0;
        required = badge.requiredShares;
        break;
      case badge_model.BadgeType.special:
        return const SizedBox();
    }

    double progress = required > 0 ? (current / required).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(badge.color),
        ),
        const SizedBox(height: 2),
        Text(
          '$current/$required',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}