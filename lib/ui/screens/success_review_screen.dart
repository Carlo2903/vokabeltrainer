import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/gamification_provider.dart';
import '../../models/badge_model.dart';

class SuccessReviewScreen extends StatelessWidget {
  const SuccessReviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gamification = context.watch<GamificationProvider>();

    if (gamification.isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF13ec5b))),
      );
    }

    final user = gamification.userProfile;
    if (user == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: Text('Kein Profil gefunden.')),
      );
    }

    final xpForNext = gamification.xpForNextLevel;
    final xpForCurrent = gamification.getXpRequiredForLevel(user.level);
    
    // Progress calculation for the progress bar
    double progress = 0.0;
    if (xpForNext > xpForCurrent) {
      progress = (user.xp - xpForCurrent) / (xpForNext - xpForCurrent);
      progress = progress.clamp(0.0, 1.0);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Erfolge', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Profile Section ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF13ec5b).withOpacity(0.3), width: 4),
                          color: theme.cardColor,
                          image: user.photoUrl != null
                              ? DecorationImage(image: NetworkImage(user.photoUrl!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: user.photoUrl == null
                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF13ec5b),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                        ),
                        child: Text(
                          'LVL ${user.level}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.displayName.isEmpty ? 'Benutzer' : user.displayName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'VOKABEL-ENTDECKER',
                    style: TextStyle(
                      color: Color(0xFF13ec5b),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress Bar
                  Container(
                    width: 200,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF13ec5b),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${xpForNext - user.xp} XP bis Level ${user.level + 1}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),

            // --- Stats Row ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildStatCard(
                    theme,
                    value: gamification.badges.length.toString(),
                    label: 'ABZEICHEN',
                    valueColor: const Color(0xFF13ec5b),
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    theme,
                    value: '15', // Placeholder for awards if needed
                    label: 'AUSZEICHNUNGEN',
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    theme,
                    value: '${user.currentStreak}',
                    label: 'SERIE',
                    icon: Icons.local_fire_department,
                    iconColor: Colors.orange,
                  ),
                ],
              ),
            ),
            
            // --- Badges Grid ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Deine Sammlung', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Alle ansehen', style: TextStyle(color: Color(0xFF13ec5b), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: gamification.badges.length + 6, // Adding some locked placeholders for visual effect
                    itemBuilder: (context, index) {
                      if (index < gamification.badges.length) {
                        return _buildBadge(gamification.badges[index]);
                      } else {
                        return _buildLockedBadge(index - gamification.badges.length);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, {required String value, required String label, IconData? icon, Color? iconColor, Color? valueColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 4),
                ],
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BadgeModel badge) {
    // Basic color mapping
    Color baseColor = const Color(0xFF13ec5b);
    if (badge.colorHex.toLowerCase() == 'fb923c' || badge.colorHex.contains('orange')) baseColor = Colors.orange;
    if (badge.colorHex.toLowerCase() == '60a5fa' || badge.colorHex.contains('blue')) baseColor = Colors.blue;

    IconData icon = Icons.military_tech;
    if (badge.iconName.contains('fire')) icon = Icons.local_fire_department;
    if (badge.iconName.contains('language')) icon = Icons.language;

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: baseColor.withOpacity(0.15),
            border: Border.all(color: baseColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: baseColor.withOpacity(0.2),
                blurRadius: 10,
              )
            ],
          ),
          child: Center(
            child: Icon(icon, color: baseColor, size: 36),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          badge.name,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildLockedBadge(int index) {
    final icons = [Icons.menu_book, Icons.bolt, Icons.psychology, Icons.groups, Icons.workspace_premium, Icons.history_edu];
    final titles = ['Eifriger Leser', 'Schneller Lerner', 'Lexikon-Experte', 'Kontaktfreudig', 'Top 1% Club', 'Etymologie-König'];
    
    return Opacity(
      opacity: 0.4,
      child: ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade800,
                border: Border.all(color: Colors.grey.shade600, width: 2),
              ),
              child: Center(
                child: Icon(icons[index % icons.length], color: Colors.grey, size: 36),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              titles[index % titles.length],
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
