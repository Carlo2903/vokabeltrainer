import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Liefert den aktuellen Auth-Zustand als Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Aktuell eingeloggter User (kann null sein)
  User? get currentUser => _auth.currentUser;

  // ── Email / Passwort ─────────────────────────────────────────────────────

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> registerWithEmail(
      String email, String password, String displayName) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Display-Name setzen
    await cred.user!.updateDisplayName(displayName.trim());
    // Userprofil in Firestore anlegen
    await _saveUserProfile(cred.user!.uid, displayName.trim(), email.trim(), null);
    return cred;
  }

  // ── Google Sign-In ───────────────────────────────────────────────────────

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // Abgebrochen

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);

    // Profil anlegen falls neuer User
    if (cred.additionalUserInfo?.isNewUser == true) {
      await _saveUserProfile(
        cred.user!.uid,
        cred.user!.displayName ?? 'User',
        cred.user!.email ?? '',
        cred.user!.photoURL,
      );
    }
    return cred;
  }

  // ── Profil-Update ────────────────────────────────────────────────────────

  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _db.collection('users').doc(uid).update({'displayName': name});
    }
  }

  Future<void> updatePhotoUrl(String url) async {
    await _auth.currentUser?.updatePhotoURL(url);
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _db.collection('users').doc(uid).update({'photoUrl': url});
    }
  }

  // ── Abmelden ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Helper ───────────────────────────────────────────────────────────────

  Future<void> _saveUserProfile(
      String uid, String displayName, String email, String? photoUrl) async {
    await _db.collection('users').doc(uid).set({
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }
}
