import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vocabulary.dart';
import '../models/vocabulary_stack.dart';
import '../models/language_pair.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Vokabeln ──────────────────────────────────────────────────────────────

  Stream<List<Vocabulary>> watchVocabularies(String languagePairId) {
    return _db
        .collection('vocabLists')
        .doc(languagePairId)
        .collection('vocabularies')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Vocabulary.fromFirestore).toList());
  }

  Future<void> addVocabulary(Vocabulary vocab) async {
    await _db
        .collection('vocabLists')
        .doc(vocab.languagePairId)
        .collection('vocabularies')
        .add(vocab.toFirestore());
  }

  Future<void> moveToStack(String languagePairId, String vocabId, VocabularyStack stack) async {
    await _db
        .collection('vocabLists')
        .doc(languagePairId)
        .collection('vocabularies')
        .doc(vocabId)
        .update({'stack': stack.firestoreValue});
  }

  Future<void> deleteVocabulary(String languagePairId, String vocabId) async {
    await _db
        .collection('vocabLists')
        .doc(languagePairId)
        .collection('vocabularies')
        .doc(vocabId)
        .delete();
  }

  // ── Sprachpaare ───────────────────────────────────────────────────────────

  Stream<List<LanguagePair>> watchLanguagePairs() {
    return _db
        .collection('vocabLists')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(LanguagePair.fromFirestore).toList());
  }

  Future<String> addLanguagePair(LanguagePair pair) async {
    final ref = await _db.collection('vocabLists').add(pair.toFirestore());
    return ref.id;
  }

  Future<void> deleteLanguagePair(String pairId) async {
    await _db.collection('vocabLists').doc(pairId).delete();
  }
}
