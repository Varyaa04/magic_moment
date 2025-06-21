import 'package:flutter/material.dart' show Colors, TextButton, StatelessWidget, Color, BuildContext, Widget, TextStyle, Icons, Icon, Text, Navigator, AlertDialog, showDialog, IconButton;

import '../pagesSettings/classesSettings/app_localizations.dart';

class HelpTooltip extends StatelessWidget {
  final String message;
  final double iconSize;
  final Color iconColor;

  const HelpTooltip({
    required this.message,
    this.iconSize = 24,
    this.iconColor = Colors.white,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.help_outline, size: iconSize, color: iconColor),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[400],
            title: Text(
              AppLocalizations.of(context)?.help ?? 'Help',
              style:  TextStyle(color: Colors.grey[900],
              fontSize: 20,),
            ),
            content: Text(
              message,
              style:  TextStyle(color: Colors.grey[900]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  AppLocalizations.of(context)?.ok ?? 'OK',
                  style:  TextStyle(color: Colors.grey[900]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}