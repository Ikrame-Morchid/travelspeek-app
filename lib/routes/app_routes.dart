import 'package:flutter/material.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/welcome/welcome_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/profile/edit_profile_screen.dart';
import '../presentation/screens/profile/language_screen.dart';
import '../presentation/screens/profile/privacy_screen.dart';
import '../presentation/screens/profile/help_support_screen.dart';
import '../presentation/screens/profile/delete_account_screen.dart';
import '../presentation/screens/reviews/reviews_feedback_screen.dart';
import '../presentation/screens/chatbot/chat_bot_screen.dart';
import '../presentation/screens/translation/translation_screen.dart';
import '../presentation/screens/monuments/monuments_list_screen.dart';
import '../presentation/screens/monuments/monuments_grid_screen.dart';
import '../presentation/screens/monuments/monument_detail_screen.dart';
import '../presentation/screens/history/history_screen.dart';
import '../presentation/screens/test/backend_test_screen.dart';
import '../data/models/monument_model.dart';

class AppRoutes {
  static const String splash          = '/';
  static const String welcome         = '/welcome';
  static const String login           = '/login';
  static const String register        = '/register';
  static const String home            = '/home';
  static const String monumentDetail  = '/monument-detail';
  static const String monumentList    = '/monuments';
  static const String monumentsGrid   = '/monuments-grid';
  static const String favorites       = '/favorites';
  static const String translation     = '/translation';
  static const String chatbot         = '/chatbot';
  static const String history         = '/history';
  static const String profile         = '/profile';
  static const String language        = '/language';
  static const String editProfile     = '/edit-profile';
  static const String deleteAccount   = '/delete-account';
  static const String reviewsFeedback = '/reviews-feedback';
  static const String privacy         = '/privacy';
  static const String helpSupport     = '/help-support';
  static const String settings        = '/settings';
  static const String backendTest     = '/backend-test';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {

      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case chatbot:
        return MaterialPageRoute(builder: (_) => const ChatBotScreen());

      case translation:
        final args = settings.arguments as Map<String, dynamic>?;
        final initialTab = args?['initialTab'] ?? 0;
        return MaterialPageRoute(
          builder: (_) => TranslationScreen(initialTab: initialTab),
        );

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());

      case language:
        return MaterialPageRoute(builder: (_) => const LanguageScreen());

      case deleteAccount:
        return MaterialPageRoute(builder: (_) => const DeleteAccountScreen());

      case reviewsFeedback:
        final args = settings.arguments as Map<String, dynamic>?;
        final initialTab = args?['initialTab'] ?? 0;
        return MaterialPageRoute(
          builder: (_) => ReviewsFeedbackScreen(initialTab: initialTab),
        );

      case privacy:
        return MaterialPageRoute(builder: (_) => const PrivacyScreen());

      case helpSupport:
        return MaterialPageRoute(builder: (_) => const HelpSupportScreen());

      case monumentList:
        return MaterialPageRoute(builder: (_) => const MonumentsListScreen());

      case monumentsGrid:
        return MaterialPageRoute(builder: (_) => const MonumentsGridScreen());

      // ✅ CORRIGÉ : accepte Monument directement OU Map{'monument': Monument}
      case monumentDetail:
        final args = settings.arguments;
        if (args is Monument) {
          return MaterialPageRoute(
            builder: (_) => MonumentDetailScreen(monument: args),
          );
        }
        if (args is Map<String, dynamic> && args['monument'] is Monument) {
          return MaterialPageRoute(
            builder: (_) => MonumentDetailScreen(monument: args['monument']),
          );
        }
        return _errorRoute('Monument data is required');

      case history:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());

      case backendTest:
        return MaterialPageRoute(builder: (_) => const BackendTestScreen());

      case favorites:
        return MaterialPageRoute(
          builder: (_) =>
              _PlaceholderScreen(routeName: settings.name ?? 'Unknown'),
        );

      default:
        return _errorRoute('No route defined for ${settings.name}');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error'), backgroundColor: Colors.red),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                Text(message,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String routeName;
  const _PlaceholderScreen({required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(routeName == '/favorites' ? 'Favorites' : 'Unknown'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text('Coming soon...',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}