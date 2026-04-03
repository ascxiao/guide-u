import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'routes/app_routes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'view_models/saved_articles_view_model.dart';
import 'view_models/article_cache_view_model.dart';
import 'widgets/connectivity_banner.dart';
import 'view_models/connectivity_view_model.dart';
import 'views/handbook_main_page.dart';
import 'views/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class _MinusTwoTextScaler extends TextScaler {
  const _MinusTwoTextScaler();

  static const double _minReadableFontSize = 8.0;

  @override
  double get textScaleFactor => 1.0;

  @override
  double scale(double fontSize) {
    return math.max(_minReadableFontSize, fontSize - 2.0);
  }

  @override
  TextScaler clamp({
    double minScaleFactor = 0,
    double maxScaleFactor = double.infinity,
  }) {
    return this;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_KEY']!,
  );

  await Hive.initFlutter();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SavedArticlesViewModel()),
        ChangeNotifierProvider(create: (_) => ArticleCacheViewModel()),
        ChangeNotifierProvider(create: (_) => ConnectivityViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = ThemeData(useMaterial3: true).textTheme;
    final brandedTextTheme = baseTextTheme.copyWith(
      displayLarge: GoogleFonts.montserrat(
        textStyle: baseTextTheme.displayLarge,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: GoogleFonts.montserrat(
        textStyle: baseTextTheme.displayMedium,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.montserrat(
        textStyle: baseTextTheme.titleLarge,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.montserrat(
        textStyle: baseTextTheme.titleMedium,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: GoogleFonts.poppins(textStyle: baseTextTheme.bodyLarge),
      bodyMedium: GoogleFonts.poppins(textStyle: baseTextTheme.bodyMedium),
      labelLarge: GoogleFonts.montserrat(
        textStyle: baseTextTheme.labelLarge,
        fontWeight: FontWeight.w600,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GuideU Handbook',
      scaffoldMessengerKey: appScaffoldMessengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        textTheme: brandedTextTheme,
      ),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: const _MinusTwoTextScaler()),
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const ConnectivityBanner(),
            ],
          ),
        );
      },
      home: const AuthGate(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;

    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        auth.currentSession,
      ),
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? auth.currentSession;
        if (session == null) {
          return const LoginScreen();
        }
        return const HandbookMainPage();
      },
    );
  }
}
