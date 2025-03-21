import 'package:MagicMoment/themeWidjets/settingsButtonIcon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/language_provider.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';

class ThemeSetPage extends StatelessWidget {
  const ThemeSetPage({super.key});

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
                  appLocalizations.appTheme,
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

                        },
                        text: appLocalizations.lightTheme,
                        icon: FluentIcons.color_20_filled,
                    ),
                    const SizedBox(height: 20),
                    SettingsButton(
                        onPressed: (){

                        },
                        text: appLocalizations.darkTheme,
                        icon: FluentIcons.color_20_filled,
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