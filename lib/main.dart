import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/firestore_service.dart';
import 'services/training_service.dart';
import 'providers/vocabulary_provider.dart';
import 'providers/language_provider.dart';
import 'providers/session_provider.dart';
import 'ui/theme/app_theme.dart';
import 'ui/widgets/app_shell.dart';
import 'ui/screens/start_session_screen.dart';
import 'ui/screens/active_learning_screen.dart';

void main() async {
  // Wichtig für den Zugriff auf die nativen Android-Resourcen
  WidgetsFlutterBinding.ensureInitialized();


  // Lädt die Konfiguration automatisch aus der google-services.json
  await Firebase.initializeApp();

  runApp(const VokabelApp());
}

class VokabelApp extends StatelessWidget {
  const VokabelApp({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final trainingService = TrainingService(firestoreService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider(firestoreService)),
        ChangeNotifierProvider(create: (_) => VocabularyProvider(firestoreService)),
        ChangeNotifierProvider(create: (_) => SessionProvider(trainingService)),
      ],
      child: MaterialApp(
        title: 'Vokabeltrainer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        initialRoute: '/',
        routes: {
          '/': (context) => const AppShell(),
          '/session/start': (context) => const StartSessionScreen(),
          '/session/active': (context) => const ActiveLearningScreen(),
        },
      ),
    );
  }
}