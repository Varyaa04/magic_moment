import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'startPage.dart';
import 'pagesSettings/classesSettings/app_localizations.dart';
import 'pagesSettings/classesSettings/language_provider.dart';
import 'pagesSettings/classesSettings/theme_provider.dart';

void main() {
  runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MyApp(),
    ),
  );
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
              primary: Colors.red,
              onPrimary: Colors.red[100]!,
              primaryContainer: Colors.deepOrange[100]!,
              secondary: Colors.green,
              surface: Colors.white,
              onSurface: Colors.black,
              onSecondary: Colors.black,
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.dark(
              primary: Colors.pink,
              onPrimary: Colors.pink[100]!,
              primaryContainer: Colors.yellow[100]!,
              secondary: Colors.teal,
              surface: Colors.black54,
              onSurface: Colors.white,
                onSecondary: Colors.grey[900]!,
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