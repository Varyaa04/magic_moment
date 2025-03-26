import 'package:MagicMoment/themeWidjets/formatButtonIcon.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'classesSettings/app_localizations.dart';

class FormatSetPage extends StatelessWidget {
  const FormatSetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final  theme = Theme.of(context);
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
              ),
              Container(
                child:  Text(
                  appLocalizations.format,
                  textAlign: TextAlign.center,
                  style:  TextStyle(
                      fontFamily: 'Oi-Regular',
                      fontSize: 26,
                      color: colorScheme.onSecondary,
                      fontWeight: FontWeight.w100
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                child: Column(
                  children: [
                    formatButtonIcon(
                        onPressed: (){
                          //логика изменения
                        },
                        text: 'PNG',
                        secondaryText: appLocalizations.pngText,
                        icon: FluentIcons.document_16_filled
                    ),
                    const SizedBox(height: 20),
                    formatButtonIcon(
                        onPressed: (){

                        },
                        text: 'JPEG',
                        secondaryText: appLocalizations.jpegText,
                        icon: FluentIcons.document_16_filled
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