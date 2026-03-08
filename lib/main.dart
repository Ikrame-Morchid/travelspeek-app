// ══════════════════════════════════════════════════════
// lib/main.dart - VERSION FINALE AVEC TOUS LES PROVIDERS
// ══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

// Theme & Config
import 'core/theme/app_theme.dart';

// Services
import 'data/services/translation_service.dart';
import 'data/services/storage_service.dart';

// Models
import 'data/models/translation_cache.dart';

// Providers
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/home_provider.dart';
import 'presentation/providers/monument_provider.dart';
import 'presentation/providers/language_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/conversation_provider.dart';
import 'presentation/providers/history_provider.dart';
import 'presentation/providers/favorite_provider.dart';
import 'presentation/providers/comment_provider.dart'; // ✅ AJOUTÉ

// Routes
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    // Initialiser StorageService (Isar principal)
    await StorageService.instance.init();
    debugPrint('✅ StorageService initialisé');

    // Initialiser Isar pour TranslationCache (séparé)
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [TranslationCacheSchema],
      directory: dir.path,
      name: 'translation_cache',
      inspector: true,
    );
    debugPrint('✅ Isar TranslationCache initialisé');

    final translationService = TranslationService(isar);
    debugPrint('✅ TranslationService créé');

    final languageProvider = LanguageProvider();
    await languageProvider.initialize();
    debugPrint('✅ LanguageProvider : ${languageProvider.currentLanguage}');

    runApp(MyApp(
      isar: isar,
      translationService: translationService,
      languageProvider: languageProvider,
    ));
  } catch (e, stackTrace) {
    debugPrint('❌ Erreur initialisation : $e');
    debugPrint('Stack trace : $stackTrace');

    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Erreur d\'initialisation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  final Isar isar;
  final TranslationService translationService;
  final LanguageProvider languageProvider;

  const MyApp({
    super.key,
    required this.isar,
    required this.translationService,
    required this.languageProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => MonumentProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ConversationProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => CommentProvider()), // ✅ AJOUTÉ
        ChangeNotifierProvider.value(value: languageProvider),
        Provider<TranslationService>.value(value: translationService),
        Provider<Isar>.value(value: isar),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, langProvider, _) {
          return Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'TravelSpeek',
                locale: langProvider.locale,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en', ''),
                  Locale('fr', ''),
                  Locale('ar', ''),
                  Locale('es', ''),
                ],
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeProvider.themeMode,
                initialRoute: AppRoutes.splash,
                onGenerateRoute: AppRoutes.generateRoute,
                builder: (context, child) {
                  return Directionality(
                    textDirection: langProvider.currentLanguage == 'ar'
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: child!,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}