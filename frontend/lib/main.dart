import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/translation_service.dart';
import 'services/auth_service.dart';
import 'views/auth/login_screen.dart';
import 'views/home/home_screen.dart';
import 'views/history/history_screen.dart';
import 'views/profile/profile_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProxyProvider<AuthService, TranslationService>(
          create: (_) => TranslationService(),
          update: (_, auth, service) => service!..updateAuth(auth),
        ),
      ],
      child: const HybridTranslatorApp(),
    ),
  );
}

class HybridTranslatorApp extends StatelessWidget {
  const HybridTranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hylator Translator',
      debugShowCheckedModeBanner: false,

      // ── Nature-Modern Light Theme ───────────────────────────────────────────
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50), // Nature Green
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFF81C784),
          surface: const Color(0xFFF9FBF9),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.outfitTextTheme(),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          color: Colors.white.withAlpha(180),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
      ),

      // ── Forest Dark Theme ───────────────────────────────────────────────────
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          primary: const Color(0xFF81C784),
          secondary: const Color(0xFFC8E6C9),
          surface: const Color(0xFF1B241B),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          color: const Color(0xFF2D3B2D).withAlpha(180),
        ),
      ),

      themeMode: ThemeMode.system,

      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) return const HomeScreen();
          return const LoginScreen();
        },
      ),

      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/history':
            return _route(const HistoryScreen(), settings);
          case '/profile':
            return _route(const ProfileScreen(), settings);
          default:
            return null;
        }
      },
    );
  }

  PageRoute _route(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}
