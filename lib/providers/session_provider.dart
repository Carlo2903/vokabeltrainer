import 'package:flutter/material.dart';
import '../models/vocabulary.dart';
import '../services/training_service.dart';

enum TranslationDirection { standard, reverse, mixed }

class SessionProvider extends ChangeNotifier {
  final TrainingService _trainingService;

  SessionProvider(this._trainingService);

  List<Vocabulary> _queue = [];
  int _currentIndex = 0;
  int _correctCount = 0;
  bool _isFinished = false;
  bool _isFlipped = false;
  TranslationDirection _direction = TranslationDirection.standard;
  int _sessionLength = 25;

  // ── Getters ──────────────────────────────────────────────────────────────

  bool get isFinished => _isFinished;
  bool get isFlipped => _isFlipped;
  bool get hasWords => _queue.isNotEmpty;
  int get currentIndex => _currentIndex;
  int get totalCount => _queue.length;
  int get correctCount => _correctCount;
  TranslationDirection get direction => _direction;
  int get sessionLength => _sessionLength;

  Vocabulary? get currentWord =>
      _queue.isNotEmpty && _currentIndex < _queue.length
          ? _queue[_currentIndex]
          : null;

  // Je nach Richtung: was wird vorne / hinten gezeigt
  String get frontText {
    final w = currentWord;
    if (w == null) return '';
    return _direction == TranslationDirection.reverse
        ? w.translation
        : w.term;
  }

  String get backText {
    final w = currentWord;
    if (w == null) return '';
    return _direction == TranslationDirection.reverse
        ? w.term
        : w.translation;
  }

  // ── Session Setup ─────────────────────────────────────────────────────────

  void setDirection(TranslationDirection dir) {
    _direction = dir;
    notifyListeners();
  }

  void setSessionLength(int length) {
    _sessionLength = length;
    notifyListeners();
  }

  void startSession(List<Vocabulary> allVocabs) {
    _queue = _trainingService.buildSession(allVocabs, _sessionLength);
    if (_direction == TranslationDirection.mixed) {
      // bei Mixed: Richtung per Wort zufällig
      _queue.shuffle();
    }
    _currentIndex = 0;
    _correctCount = 0;
    _isFinished = false;
    _isFlipped = false;
    notifyListeners();
  }

  void flipCard() {
    _isFlipped = !_isFlipped;
    notifyListeners();
  }

  // ── Bewertung ─────────────────────────────────────────────────────────────

  Future<void> markCorrect() async {
    final word = currentWord;
    if (word == null) return;
    await _trainingService.markCorrect(word);
    _correctCount++;
    _advance();
  }

  Future<void> markWrong() async {
    final word = currentWord;
    if (word == null) return;
    await _trainingService.markWrong(word);
    _advance();
  }

  void _advance() {
    _isFlipped = false;
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
    } else {
      _isFinished = true;
    }
    notifyListeners();
  }

  void resetSession() {
    _queue = [];
    _currentIndex = 0;
    _correctCount = 0;
    _isFinished = false;
    _isFlipped = false;
    notifyListeners();
  }
}
