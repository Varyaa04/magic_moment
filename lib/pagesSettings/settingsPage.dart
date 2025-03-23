import 'package:MagicMoment/pagesSettings/formatSetPage.dart';
import 'package:MagicMoment/pagesSettings/langSetPage.dart';
import 'package:MagicMoment/pagesSettings/themeSetPage.dart';
import 'package:MagicMoment/themeWidjets/settingsButtonIcon.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    final  theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: colorScheme.surface,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  child: Tooltip(
                    message: appLocalizations.back,
                    child: IconButton(
                    onPressed: (){
                      Navigator.pop(context);
                    },
                    icon: const Icon(FluentIcons.arrow_left_16_filled),
                    color: colorScheme.onSurface,
                    iconSize: 30,
                  ),
                ),
                ),
              ],
            ),  Text(
                appLocalizations.settings,
                textAlign: TextAlign.center,
                style:  TextStyle(
                  fontFamily: 'Oi-Regular',
                  fontSize: 26,
                  color: colorScheme.onSecondary,
                  fontWeight: FontWeight.w100
                ),
              ),
            const SizedBox(height: 40),
            Container(
              child: Column(
                children: [
                  SettingsButton(
                      onPressed: (){
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LangSetPage()
                            )
                        );
                      },
                      text: appLocalizations.lang,
                      icon: FluentIcons.earth_16_filled
                  ),
                  const SizedBox(height: 20),
                  SettingsButton(
                      onPressed: (){
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ThemeSetPage()
                            )
                        );
                      },
                      text: appLocalizations.theme,
                      icon: FluentIcons.color_20_filled
                  ),
                  const SizedBox(height: 20),
                  SettingsButton(
                      onPressed: (){
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const FormatSetPage()
                            )
                        );
                      },
                      text: appLocalizations.format,
                      icon: FluentIcons.document_image_20_filled
                  ),
                ],
              ),
            )
          ],
        )
      ),
    );
  }
}