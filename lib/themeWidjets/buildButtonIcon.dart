import 'package:flutter/material.dart';


class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final String? secondaryText;
  final IconData icon;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.secondaryText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 2),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontFamily: 'Comfortaa',
                    fontWeight: FontWeight.bold
                  ),
                ),
                if (secondaryText != null)
                  Text(
                    secondaryText!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
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