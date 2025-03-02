import 'dart:io';
import 'package:flutter/material.dart';

class EditPage extends StatelessWidget {
  final File? imageFile;

  const EditPage({super.key, this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Page'),
      ),
      body: Center(
        child: imageFile != null
            ? Image.file(imageFile!)
            : const Text('No image selected.'),
      ),
    );
  }
}