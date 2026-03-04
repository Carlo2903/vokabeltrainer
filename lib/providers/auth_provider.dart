import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider(this._authService) {
    _init();
  }

  User? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<User?>? _subscription;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get errorMessage => _errorMessage;

  void _init() {
    _subscription = _authService.authStateChanges.listen((user) {
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  // ── Email/Passwort ───────────────────────────────────────────────────────

  Future<bool> signIn(String email, String password) async {
    _setError(null);
    try {
      await _authService.signInWithEmail(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapAuthError(e.code));
      return false;
    }
  }

  Future<bool> register(String email, String password, String displayName) async {
    _setError(null);
    try {
      await _authService.registerWithEmail(email, password, displayName);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_mapAuthError(e.code));
      return false;
    }
  }

  // ── Google ───────────────────────────────────────────────────────────────

  Future<bool> signInWithGoogle() async {
    _setError(null);
    try {
      final cred = await _authService.signInWithGoogle();
      return cred != null;
    } on FirebaseAuthException catch (e) {
      _setError(_mapAuthError(e.code));
      return false;
    } catch (_) {
      _setError('Google-Login fehlgeschlagen.');
      return false;
    }
  }

  // ── Abmelden ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _authService.signOut();
  }

  // ── Profilbild ───────────────────────────────────────────────────────────

  Future<void> updatePhotoUrl(String url) async {
    await _authService.updatePhotoUrl(url);
    notifyListeners();
  }

  // ── Helper ───────────────────────────────────────────────────────────────

  void _setError(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Kein Account mit dieser E-Mail gefunden.';
      case 'wrong-password':
        return 'Falsches Passwort.';
      case 'email-already-in-use':
        return 'Diese E-Mail-Adresse wird bereits verwendet.';
      case 'invalid-email':
        return 'Ungültige E-Mail-Adresse.';
      case 'weak-password':
        return 'Das Passwort muss mindestens 6 Zeichen lang sein.';
      case 'network-request-failed':
        return 'Keine Internetverbindung.';
      default:
        return 'Fehler: $code';
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
