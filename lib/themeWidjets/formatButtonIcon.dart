import 'package:flutter/material.dart';

class formatButtonIcon extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final String? secondaryText;
  final IconData icon;

  const formatButtonIcon({
    super.key,
    required this.onPressed,
    required this.text,
    this.secondaryText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {

    final  theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      height: 70,
      width: 400,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.onSurface, width: 1),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.onSurface, size: 50, ),
            const SizedBox(width: 10,),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  textAlign: TextAlign.center,
                  text,
                  style:  TextStyle(
                      fontSize: 26,
                      color: colorScheme.onSurface,
                      fontFamily: 'Comfortaa',
                      fontWeight: FontWeight.bold
                  ),
                ),
                if (secondaryText != null)
                  Text(
                    secondaryText!,
                    style:  TextStyle(
                        fontSize: 14,
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