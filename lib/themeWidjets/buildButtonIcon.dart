import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class IconButtonStart extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String text;

  const IconButtonStart({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 246, 222, 255),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          height: 100,
          width: 100,
          child: IconButton(
            iconSize: 50,
            icon: Icon(icon),
            color: const Color.fromARGB(255, 96, 15, 91),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'RuslanDisplay-Regular',
            color: Color.fromARGB(255, 96, 15, 91),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
