import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/language_pair.dart';
import '../theme/app_theme.dart';

class AddLanguageDialog extends StatefulWidget {
  final Future<void> Function(LanguagePair pair) onAdd;
  const AddLanguageDialog({super.key, required this.onAdd});

  @override
  State<AddLanguageDialog> createState() => _AddLanguageDialogState();
}

class _AddLanguageDialogState extends State<AddLanguageDialog> {
  final _titleController = TextEditingController();
  final _sourceController = TextEditingController(text: 'Deutsch');
  final _targetController = TextEditingController(text: 'Englisch');
  final _sourceFlagController = TextEditingController(text: '🇩🇪');
  final _targetFlagController = TextEditingController(text: '🇬🇧');
  final _levelController = TextEditingController(text: 'A1');
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _sourceController.dispose();
    _targetController.dispose();
    _sourceFlagController.dispose();
    _targetFlagController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_sourceController.text.isEmpty || _targetController.text.isEmpty) return;

    setState(() => _isSaving = true); // Ladezustand starten

    try {
      await widget.onAdd(LanguagePair(
        id: '',
        title: _titleController.text.trim().isEmpty ? 'Neuer Kurs' : _titleController.text.trim(),
        sourceLanguage: _sourceController.text.trim(),
        sourceFlag: _sourceFlagController.text.trim(),
        targetLanguage: _targetController.text.trim(),
        targetFlag: _targetFlagController.text.trim(),
        level: _levelController.text.trim(),
        createdAt: DateTime.now(),
      ));
      // Wenn erfolgreich: Dialog schließen
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // Wenn ein Fehler passiert: Ladezustand stoppen und Fehler zeigen
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speichern fehlgeschlagen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Neue Sprache',
                style: GoogleFonts.lexend(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Definiere ein neues Sprachpaar.',
                style: GoogleFonts.lexend(fontSize: 13, color: AppColors.textSecondary)),
            _field(_titleController, 'Kurs-Titel', hint: 'z.B. Mein Training'),
            const SizedBox(height: 12),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _field(_sourceFlagController, 'Flag', hint: '🇩🇪')),
              const SizedBox(width: 10),
              Expanded(flex: 3, child: _field(_sourceController, 'Quellsprache', hint: 'Deutsch')),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_targetFlagController, 'Flag', hint: '🇬🇧')),
              const SizedBox(width: 10),
              Expanded(flex: 3, child: _field(_targetController, 'Zielsprache', hint: 'Englisch')),
            ]),
            const SizedBox(height: 12),
            _field(_levelController, 'Level (optional)', hint: 'A1, B2, N5 ...'),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Abbrechen', style: GoogleFonts.lexend()),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(_isSaving ? '...' : 'Hinzufügen',
                    style: GoogleFonts.lexend(fontWeight: FontWeight.w700)),
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {String hint = ''}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.lexend(fontSize: 10, color: AppColors.textMuted,
          fontWeight: FontWeight.w700, letterSpacing: 1)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        style: GoogleFonts.lexend(fontSize: 14, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.lexend(color: AppColors.textMuted, fontSize: 14),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ]);
  }
}
