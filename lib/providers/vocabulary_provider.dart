import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vocabulary.dart';
import '../models/vocabulary_stack.dart';
import '../services/firestore_service.dart';

class VocabularyProvider extends ChangeNotifier {
  final FirestoreService _service;
  String? _uid;

  VocabularyProvider(this._service);

  List<Vocabulary> _vocabularies = [];
  StreamSubscription<List<Vocabulary>>? _subscription;
  String? _currentLanguagePairId;
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<Vocabulary> get all => _vocabularies;

  List<Vocabulary> get masterBlock =>
      _vocabularies.where((v) => v.stack == VocabularyStack.masterBlock).toList();

  List<Vocabulary> get training =>
      _vocabularies.where((v) => v.stack == VocabularyStack.training).toList();

  List<Vocabulary> get review =>
      _vocabularies.where((v) => v.stack == VocabularyStack.review).toList();

  List<Vocabulary> get mastered =>
      _vocabularies.where((v) => v.stack == VocabularyStack.mastered).toList();

  int get totalWords => _vocabularies.length;

  double get masteryPercent =>
      totalWords == 0 ? 0 : mastered.length / totalWords;

  /// Wird vom main.dart aufgerufen wenn sich der User ändert
  void setUid(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _subscription?.cancel();
    _vocabularies = [];
    _currentLanguagePairId = null;
    notifyListeners();
  }

  void subscribeToLanguagePair(String languagePairId) {
    if (_uid == null) return;
    if (_currentLanguagePairId == languagePairId) return;
    _currentLanguagePairId = languagePairId;
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _service.watchVocabularies(_uid!, languagePairId).listen((list) {
      _vocabularies = list;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addVocabulary(Vocabulary vocab) async {
    if (_uid == null) return;
    await _service.addVocabulary(_uid!, vocab);
  }

  Future<void> importFromCatalog(String sourceLang, String targetLang, String pairId) async {
    if (_uid == null) return;
    
    // Bestimmen, welche Sprache aus dem Katalog geladen werden muss
    // Der Katalog enthält deutsche Begriffe ('term') und Übersetzungen in 'en' oder 'es' ('translation')
    String catalogLang = '';
    bool isReverse = false; // z.B. Englisch -> Deutsch
    
    if (sourceLang == 'Deutsch' && targetLang == 'Englisch') {
      catalogLang = 'en';
    } else if (sourceLang == 'Deutsch' && targetLang == 'Spanisch') {
      catalogLang = 'es';
    } else if (sourceLang == 'Englisch' && targetLang == 'Deutsch') {
      catalogLang = 'en';
      isReverse = true;
    } else if (sourceLang == 'Spanisch' && targetLang == 'Deutsch') {
      catalogLang = 'es';
      isReverse = true;
    } else if (sourceLang == 'Englisch' && targetLang == 'Spanisch') {
       // Für Englisch->Spanisch laden wir die englischen und spanischen Begriffe und matchen sie 
       // Das ist mit der aktuellen Datenstruktur komplex. Wir laden stattdessen die 'es' Einträge und tauschen term/translation wenn nötig
       // DA DIE DATENSTRUKTUR (term=Deutsch, translation=Fremdsprache) FIX IST:
       // Wir ignorieren Englisch<->Spanisch im automatischen Import erstmal oder bauen einen komplizierteren Matcher.
       // Einfachste Lösung: Import für diese Kombination überspringen.
       return;
    } else if (sourceLang == 'Spanisch' && targetLang == 'Englisch') {
       return;
    }

    if (catalogLang.isEmpty) return;

    final catalogItems = await _service.fetchGlobalCatalog(catalogLang);
    final batch = FirebaseFirestore.instance.batch();
    
    for (var item in catalogItems) {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('vocabLists')
          .doc(pairId)
          .collection('vocabularies')
          .doc();

      final String term = isReverse ? item['translation'] : item['term'];
      final String translation = isReverse ? item['term'] : item['translation'];

      final vocab = Vocabulary(
        id: docRef.id,
        term: term,
        description: '', // Keine Description im Katalog
        translation: translation,
        stack: VocabularyStack.training,
        languagePairId: pairId,
        createdAt: DateTime.now(),
      );

      batch.set(docRef, vocab.toFirestore());
    }

    await batch.commit();
  }

  Future<void> moveToStack(String id, VocabularyStack stack) async {
    if (_uid == null || _currentLanguagePairId == null) return;
    await _service.moveToStack(_uid!, _currentLanguagePairId!, id, stack);
  }

  Future<void> deleteVocabulary(String id) async {
    if (_uid == null || _currentLanguagePairId == null) return;
    await _service.deleteVocabulary(_uid!, _currentLanguagePairId!, id);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
