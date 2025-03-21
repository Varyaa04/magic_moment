import 'package:MagicMoment/themeWidjets/settingsButtonIcon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'classesSettings/language_provider.dart';
import 'classesSettings/app_localizations.dart';

class LangSetPage extends StatelessWidget {
  const LangSetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, right: 10),
                    child: Tooltip(
                      message: appLocalizations.back,
                      child: IconButton(
                      onPressed: (){
                        Navigator.pop(context);
                      },
                      icon: const Icon(FluentIcons.arrow_left_16_filled),
                      color: Colors.black,
                      iconSize: 30,
                    ),
                  ),
                  ),
                ],
              ),
              Container(
                child:  Text(
                  appLocalizations.appTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'Oi-Regular',
                      fontSize: 26,
                      color: Colors.black,
                      fontWeight: FontWeight.w100
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                child: Column(
                  children: [
                    SettingsButton(
                        onPressed: (){
                          languageProvider.setLocale(const Locale('ru')); // Русский
                        },
                        text: appLocalizations.russian,
                        icon: FluentIcons.earth_16_filled
                    ),
                    const SizedBox(height: 20),
                    SettingsButton(
                        onPressed: (){
                          languageProvider.setLocale(const Locale('en')); // Английский
                        },
                        text: appLocalizations.english,
                        icon: FluentIcons.earth_16_filled
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