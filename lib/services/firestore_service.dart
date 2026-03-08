import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vocabulary.dart';
import '../models/vocabulary_stack.dart';
import '../models/language_pair.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Basis-Pfade (user-scoped) ─────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _vocabLists(String uid) =>
      _db.collection('users').doc(uid).collection('vocabLists');

  CollectionReference<Map<String, dynamic>> _vocabularies(
          String uid, String languagePairId) =>
      _vocabLists(uid).doc(languagePairId).collection('vocabularies');

  // ── Vokabeln ──────────────────────────────────────────────────────────────

  Stream<List<Vocabulary>> watchVocabularies(String uid, String languagePairId) {
    return _vocabularies(uid, languagePairId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Vocabulary.fromFirestore).toList());
  }

  Future<void> addVocabulary(String uid, Vocabulary vocab) async {
    await _vocabularies(uid, vocab.languagePairId).add(vocab.toFirestore());
  }

  Future<void> moveToStack(
      String uid, String languagePairId, String vocabId, VocabularyStack stack) async {
    await _vocabularies(uid, languagePairId)
        .doc(vocabId)
        .update({'stack': stack.firestoreValue});
  }

  Future<void> deleteVocabulary(
      String uid, String languagePairId, String vocabId) async {
    await _vocabularies(uid, languagePairId).doc(vocabId).delete();
  }

  // ── Sprachpaare ───────────────────────────────────────────────────────────

  Stream<List<LanguagePair>> watchLanguagePairs(String uid) {
    return _vocabLists(uid)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(LanguagePair.fromFirestore).toList());
  }

  Future<String> addLanguagePair(String uid, LanguagePair pair) async {
    final ref = await _vocabLists(uid).add(pair.toFirestore());
    return ref.id;
  }

  Future<void> deleteLanguagePair(String uid, String pairId) async {
    await _vocabLists(uid).doc(pairId).delete();
  }

  // ── Userprofil ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    await _db
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  // ── Global Catalog ────────────────────────────────────────────────────────

  Future<void> uploadGlobalCatalog(List<Map<String, dynamic>> items) async {
    final batch = _db.batch();
    final collection = _db.collection('global_catalog');

    for (var item in items) {
      final docRef = collection.doc();
      batch.set(docRef, item);
    }

    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> fetchGlobalCatalog(String language) async {
    final snapshot = await _db
        .collection('global_catalog')
        .where('language', isEqualTo: language)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
