import 'dart:async';
import 'package:flutter/material.dart';
import '../models/language_pair.dart';
import '../services/firestore_service.dart';

class LanguageProvider extends ChangeNotifier {
  final FirestoreService _service;

  LanguageProvider(this._service) {
    _subscribe();
  }

  List<LanguagePair> _pairs = [];
  LanguagePair? _selected;
  StreamSubscription<List<LanguagePair>>? _subscription;
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  List<LanguagePair> get pairs => _pairs;
  LanguagePair? get selected => _selected;

  void _subscribe() {
    _subscription = _service.watchLanguagePairs().listen((list) {
      _pairs = list;
      _isLoading = false;
      // Automatisch erstes Paar auswählen, wenn noch keins gewählt
      if (_selected == null && list.isNotEmpty) {
        _selected = list.first;
      }
      notifyListeners();
    });
  }

  void selectPair(LanguagePair pair) {
    _selected = pair;
    notifyListeners();
  }

  Future<void> addLanguagePair(LanguagePair pair) async {
    final id = await _service.addLanguagePair(pair);
    // Neu angelegtes Paar direkt auswählen
    final created = LanguagePair(
      id: id,
      title: pair.title,
      sourceLanguage: pair.sourceLanguage,
      sourceFlag: pair.sourceFlag,
      targetLanguage: pair.targetLanguage,
      targetFlag: pair.targetFlag,
      level: pair.level,
      createdAt: pair.createdAt,
    );
    _selected = created;
    notifyListeners();
  }

  Future<void> deleteLanguagePair(String pairId) async {
    await _service.deleteLanguagePair(pairId);
    if (_selected?.id == pairId) {
      _selected = _pairs.where((p) => p.id != pairId).firstOrNull;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
