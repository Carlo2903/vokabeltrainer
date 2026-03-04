import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/vocabulary.dart';
import '../../models/vocabulary_stack.dart';
import '../../providers/vocabulary_provider.dart';
import '../../providers/language_provider.dart';
import '../theme/app_theme.dart';

class AddVocabularyScreen extends StatefulWidget {
  const AddVocabularyScreen({super.key});

  @override
  State<AddVocabularyScreen> createState() => _AddVocabularyScreenState();
}

class _AddVocabularyScreenState extends State<AddVocabularyScreen> {
  final _termController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _translationController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _termController.dispose();
    _descriptionController.dispose();
    _translationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final term = _termController.text.trim();
    final translation = _translationController.text.trim();
    if (term.isEmpty || translation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Begriff und Übersetzung sind erforderlich',
            style: GoogleFonts.lexend())),
      );
      return;
    }

    final langProv = context.read<LanguageProvider>();
    final vocabProv = context.read<VocabularyProvider>();
    final pair = langProv.selected;
    if (pair == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bitte zuerst ein Sprachpaar wählen.',
            style: GoogleFonts.lexend())),
      );
      return;
    }

    setState(() => _isSaving = true);
    final vocab = Vocabulary(
      id: '',
      term: term,
      description: _descriptionController.text.trim(),
      translation: translation,
      stack: VocabularyStack.training,
      languagePairId: pair.id,
      createdAt: DateTime.now(),
    );
    await vocabProv.addVocabulary(vocab);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final pair = context.watch<LanguageProvider>().selected;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C0A),
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0A0C0A),
              border: Border(bottom: BorderSide(color: Color(0xFF333633))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Zurück',
                      style: GoogleFonts.lexend(color: AppColors.mastered, fontSize: 15)),
                ),
                Text('Vokabeln hinzufügen',
                    style: GoogleFonts.lexend(
                        fontSize: 17, color: Colors.white, fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text('Weiter',
                      style: GoogleFonts.lexend(
                          color: AppColors.mastered, fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
              child: Column(children: [
                // Sprachpaar-Selektor
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1C1A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF333633)),
                  ),
                  child: Row(children: [
                    Expanded(child: _langButton(
                        flag: pair?.sourceFlag ?? '🏳️',
                        label: pair?.sourceLanguage ?? 'Source')),
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.mastered,
                        boxShadow: [BoxShadow(color: AppColors.mastered.withValues(alpha: 0.25),
                            blurRadius: 12)],
                      ),
                      child: const Icon(Icons.swap_horiz, color: Colors.black, size: 20),
                    ),
                    Expanded(child: _langButton(
                        flag: pair?.targetFlag ?? '🏳️',
                        label: pair?.targetLanguage ?? 'Target')),
                  ]),
                ),
                const SizedBox(height: 28),
                // The Word
                _buildFieldLabel('DAS WORT', trailing: Row(children: [
                  const Icon(Icons.auto_awesome, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('Smart Suggest',
                      style: GoogleFonts.lexend(fontSize: 10, color: AppColors.textMuted,
                          fontWeight: FontWeight.w700, letterSpacing: 1)),
                ])),
                const SizedBox(height: 8),
                _buildTextField(_termController,
                    hint: 'Begriff eingeben', fontSize: 22, fontBold: true),
                const SizedBox(height: 22),
                // Definition
                _buildFieldLabel('DEFINITION / CONTEXT'),
                const SizedBox(height: 8),
                _buildTextArea(_descriptionController, hint: 'Beschreibe die Bedeutung...'),
                const SizedBox(height: 22),
                // Translation
                _buildFieldLabel('ÜBERSETZUNG', trailing: Row(children: [
                  const Icon(Icons.translate, size: 14, color: AppColors.mastered),
                  const SizedBox(width: 4),
                  Text('Auto-fill',
                      style: GoogleFonts.lexend(fontSize: 10, color: AppColors.mastered,
                          fontWeight: FontWeight.w700)),
                ])),
                const SizedBox(height: 8),
                _buildTextField(_translationController,
                    hint: 'Übersetzung eingeben', fontSize: 18),
                const SizedBox(height: 22),
                // Stammblock-Hinweis
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1C1A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF333633)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF333633),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: const Icon(Icons.folder, color: AppColors.masterBlock),
                    ),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('ZIEL-STAPEL',
                          style: GoogleFonts.lexend(fontSize: 9, color: AppColors.textMuted,
                              fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                      Text('Stammblock',
                          style: GoogleFonts.lexend(fontSize: 13, color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ]),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  ]),
                ),
              ]),
            ),
          ),
        ]),
      ),
      // Save Button
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        color: const Color(0xFF0A0C0A),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Speichere...' : 'Speichern',
                style: GoogleFonts.lexend(fontWeight: FontWeight.w800,
                    letterSpacing: 1.5, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mastered,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 10,
              shadowColor: AppColors.mastered,
            ),
          ),
        ),
      ),
    );
  }

  Widget _langButton({required String flag, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(children: [
        Text(flag, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(label.toUpperCase(),
            style: GoogleFonts.lexend(fontSize: 10, color: AppColors.textSecondary,
                fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const Icon(Icons.expand_more, size: 14, color: AppColors.textMuted),
      ]),
    );
  }

  Widget _buildFieldLabel(String label, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.lexend(fontSize: 10, color: AppColors.mastered,
                fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        ?trailing,
      ],
    );
  }

  Widget _buildTextField(TextEditingController ctrl,
      {required String hint, double fontSize = 16, bool fontBold = false}) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.lexend(
          fontSize: fontSize, color: Colors.white,
          fontWeight: fontBold ? FontWeight.w700 : FontWeight.w400),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFF252725),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF333633)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF333633)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.mastered, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      ),
    );
  }

  Widget _buildTextArea(TextEditingController ctrl, {required String hint}) {
    return TextField(
      controller: ctrl,
      maxLines: 3,
      style: GoogleFonts.lexend(fontSize: 15, color: Colors.white.withValues(alpha: 0.9), height: 1.5),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFF252725),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF333633)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF333633)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.mastered, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}
