import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/language_pair.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/vocabulary_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/add_language_dialog.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback? onProfileTap;
  const DashboardScreen({super.key, this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageProvider, VocabularyProvider>(
      builder: (context, langProv, vocabProv, _) {
        final selectedPair = langProv.selected;
        if (selectedPair != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {

            vocabProv.subscribeToLanguagePair(selectedPair.id);
          });
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 28),
                        _buildStatsRow(vocabProv),
                        const SizedBox(height: 28),
                        _buildSectionTitle(context, 'Aktive Kurse'),
                        const SizedBox(height: 16),
                        if (selectedPair != null)
                          _buildActiveCourseCard(context, selectedPair, vocabProv),
                        const SizedBox(height: 16),
                        ..._buildInactiveCourses(context, langProv, selectedPair),
                        const SizedBox(height: 16),
                        _buildAddLanguageButton(context, langProv),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final displayName = user?.displayName ?? 'Vokabeltrainer';
    final photoUrl = user?.photoURL;
    final initials = displayName.trim().isNotEmpty ? displayName.trim()[0].toUpperCase() : 'V';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Willkommen,',
                style: GoogleFonts.lexend(
                    fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w300)),
            Text(displayName,
                style: GoogleFonts.lexend(
                    fontSize: 24, color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent]),
            ),
            child: photoUrl != null && photoUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      photoUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Center(child: Text(initials,
                              style: GoogleFonts.lexend(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w700))),
                    ),
                  )
                : Center(
                    child: Text(initials,
                        style: GoogleFonts.lexend(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(VocabularyProvider vocabProv) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(
          icon: Icons.local_fire_department,
          iconColor: AppColors.accent,
          label: 'TÄGLICHE SERIE',
          value: '0',
          unit: 'tage',
        )),
        const SizedBox(width: 14),
        Expanded(child: _buildStatCard(
          icon: Icons.auto_awesome,
          iconColor: AppColors.primary,
          label: 'GELERNTE WÖRTER',
          value: '${vocabProv.mastered.length}',
          unit: 'insgesamt',
        )),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -4,
            right: -4,
            child: Icon(icon, size: 44, color: iconColor.withValues(alpha: 0.2)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.lexend(
                      fontSize: 9, color: iconColor,
                      fontWeight: FontWeight.w700, letterSpacing: 1.4)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value,
                      style: GoogleFonts.lexend(
                          fontSize: 30, color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  Text(unit,
                      style: GoogleFonts.lexend(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: GoogleFonts.lexend(
                fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildActiveCourseCard(
      BuildContext context, LanguagePair pair, VocabularyProvider vocabProv) {
    final trainingCount = vocabProv.training.length;
    final reviewCount = vocabProv.review.length;
    final masteredCount = vocabProv.mastered.length;
    final total = vocabProv.totalWords;
    final masteryPercent = total == 0 ? 0.0 : vocabProv.masteryPercent;


    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(pair.sourceFlag, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(pair.title,
                      style: GoogleFonts.lexend(
                          fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700)),
                  Text('→ ${pair.targetLanguage}  •  $total Wörter',
                      style: GoogleFonts.lexend(
                          fontSize: 11, color: AppColors.textSecondary)),
                ]),
              ]),
              Text('${(masteryPercent * 100).toStringAsFixed(0)}% insgesamt',
                  style: GoogleFonts.lexend(
                      fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 20),
          // Balken-Diagramm
          Row(
            children: [
              _buildStackBar('Lernen', trainingCount, total, AppColors.surfaceLight),
              const SizedBox(width: 12),
              _buildStackBar('Wiederholung', reviewCount, total, AppColors.primary),
              const SizedBox(width: 12),
              _buildStackBar('Gemeistert', masteredCount, total, AppColors.success),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/session/start'),
              icon: const Icon(Icons.bolt),
              label: const Text('Trainingseinheit starten'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStackBar(String label, int count, int total, Color color) {
    final h = total == 0 ? 0.0 : (count / total).clamp(0.02, 1.0);
    return Expanded(
      child: Column(children: [
        SizedBox(
          height: 80,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.all(3),
            child: FractionallySizedBox(
              heightFactor: h,
              widthFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8)],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: GoogleFonts.lexend(
                fontSize: 9, color: AppColors.textSecondary,
                fontWeight: FontWeight.w500, letterSpacing: 0.5)),
        Text('$count',
            style: GoogleFonts.lexend(
                fontSize: 13, color: color == AppColors.surfaceLight ? Colors.white : color,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }

  List<Widget> _buildInactiveCourses(
      BuildContext context, LanguageProvider langProv, LanguagePair? selected) {
    final others = langProv.pairs.where((p) => p.id != selected?.id).toList();
    return others.map((pair) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => langProv.selectPair(pair),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(child: Text(pair.sourceFlag, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(pair.title,
                    style: GoogleFonts.lexend(
                        fontSize: 15, color: Colors.white, fontWeight: FontWeight.w700)),
                Text('→ ${pair.targetLanguage}',
                    style: GoogleFonts.lexend(fontSize: 12, color: AppColors.textMuted)),
              ])),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    )).toList();
  }

  Widget _buildAddLanguageButton(BuildContext context, LanguageProvider langProv) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AddLanguageDialog(onAdd: (pair) => langProv.addLanguagePair(pair)),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(
              color: AppColors.border, width: 2,
              style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(20),
          color: AppColors.surface.withValues(alpha: 0.2),
        ),
        child: Column(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.add, color: AppColors.textMuted, size: 20),
          ),
          const SizedBox(height: 8),
          Text('NEUE SPRACHE HINZUFÜGEN',
              style: GoogleFonts.lexend(
                  fontSize: 10, color: AppColors.textMuted,
                  fontWeight: FontWeight.w700, letterSpacing: 1.8)),
        ]),
      ),
    );
  }
}
