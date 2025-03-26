import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'classesSettings/theme_provider.dart';

class ThemeSetPage extends StatelessWidget {
  const ThemeSetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: colorScheme.onInverseSurface,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, right: 10),
                  child: Tooltip(
                    message: appLocalizations.back,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(FluentIcons.arrow_left_16_filled),
                      color: colorScheme.onSecondary,
                      iconSize: 30,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              appLocalizations.appTheme,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Oi-Regular',
                fontSize: 26,
                color: colorScheme.onSecondary,
                fontWeight: FontWeight.w100,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              height: 70,
              width: 400,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.onSurface, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FluentIcons.color_20_filled,
                    size: 50,
                    color: colorScheme.onSurface,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    appLocalizations.darkTheme,
                    style: TextStyle(
                      fontSize: 26,
                      color: colorScheme.onSurface,
                      fontFamily: 'Comfortaa',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Switch.adaptive(
                    value: isDarkMode,
                    onChanged: (bool value) {
                      themeProvider.setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}