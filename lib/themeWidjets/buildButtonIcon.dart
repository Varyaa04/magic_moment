import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/theme_provider.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final String? secondaryText;
  final IconData icon;
  final bool isSmall;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.secondaryText,
    required this.icon,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final double buttonHeight = isSmall ? 50 : 60;
    final double buttonWidth = isSmall ? 130 : 150;
    final iconSize = isSmall ? 18.0 : 24.0;
    final textSize = isSmall ? 12.0 : 14.0;
    final padding = isSmall
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

    return Container(
      height: buttonHeight,
      width: buttonWidth,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.onSurface, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: colorScheme.onSurface),
            SizedBox(width: isSmall ? 6 : 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: TextStyle(
                      fontSize: textSize,
                      color: colorScheme.onSurface,
                      fontFamily: 'Comfortaa',
                      fontWeight: FontWeight.bold
                  ),
                ),
                if (secondaryText != null)
                  Text(
                    secondaryText!,
                    style: TextStyle(
                        fontSize: textSize,
                        color: colorScheme.onSurface,
                        fontFamily: 'Comfortaa',
                        fontWeight: FontWeight.bold
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}