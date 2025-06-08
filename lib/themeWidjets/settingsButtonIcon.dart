import 'package:flutter/material.dart';

class SettingsButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final IconData icon;

  const SettingsButton({
    super.key,
    required this.onPressed,
    required this.text,
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 40),
            Icon(icon, color: colorScheme.onSurface, size: 50),
            Expanded(
              child: Text(
                textAlign: TextAlign.center,
                text,
                style:  TextStyle(
                    fontSize: 26,
                    color: colorScheme.onSurface,
                    fontFamily: 'Comfortaa',
                    fontWeight: FontWeight.bold
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}