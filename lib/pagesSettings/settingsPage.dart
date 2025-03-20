import 'package:MagicMoment/pagesSettings/formatSetPage.dart';
import 'package:MagicMoment/pagesSettings/langSetPage.dart';
import 'package:MagicMoment/pagesSettings/themeSetPage.dart';
import 'package:MagicMoment/themeWidjets/settingsButtonIcon.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  child: Tooltip(
                    message: 'Назад',
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
              child: const Text(
                'НАСТРОЙКИ',
                textAlign: TextAlign.center,
                style: TextStyle(
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
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LangSetPage()
                            )
                        );
                      },
                      text: 'язык',
                      icon: FluentIcons.earth_16_filled
                  ),
                  const SizedBox(height: 20),
                  SettingsButton(
                      onPressed: (){
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ThemeSetPage()
                            )
                        );
                      },
                      text: 'тема',
                      icon: FluentIcons.color_20_filled
                  ),
                  const SizedBox(height: 20),
                  SettingsButton(
                      onPressed: (){
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => FormatSetPage()
                            )
                        );
                      },
                      text: 'формат фото',
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