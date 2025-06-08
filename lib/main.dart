import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'startPage.dart';
import 'pagesSettings/classesSettings/app_localizations.dart';
import 'pagesSettings/classesSettings/language_provider.dart';
import 'pagesSettings/classesSettings/theme_provider.dart';
import 'database/magicMomentDatabase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Только самое необходимое для показа первого экрана
  await Future.wait([
    dotenv.load(fileName: '.env'),
    MagicMomentDatabase.instance.initBasic(), // Только базовая инициализация
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );

  // Остальную инициализацию - в фоне
  void unawaited(Future<void> future) {}
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageProvider, ThemeProvider>(
      builder: (context, languageProvider, themeProvider, child) {
        return MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.light(
              primary: Colors.pinkAccent,
              onPrimary: Colors.red[100]!,
              primaryContainer: Colors.deepOrange[100]!,
              secondary: Colors.green,
              surface: Colors.white,
              onSurface: Colors.black,
              onSecondary: Colors.black,
              onInverseSurface: Colors.white,
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.dark(
              primary: Colors.pink,
              onPrimary: Colors.pink[100]!,
              primaryContainer: Colors.yellow[100]!,
              secondary: Colors.teal,
              surface: Colors.grey[700]!,
              onSurface: Colors.white,
                onSecondary: Colors.grey[600]!,
              onInverseSurface: Colors.grey[900]!,
            ),
          ),
          themeMode: themeProvider.themeMode,
          home: const StartPage(),
          locale: languageProvider.locale,
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('ru', 'RU'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        );
      },
    );
  }


}