import 'dart:io';
import 'dart:typed_data';
import 'package:MagicMoment/pagesEditing/background/removeBackground.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:MagicMoment/database/editHistory.dart';
import 'package:MagicMoment/database/magicMomentDatabase.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';

import 'blurBackground.dart';
import 'changeBackground.dart';

class BackgroundPanel extends StatefulWidget {
  final Uint8List image;
  final int imageId;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final Function(Uint8List, {String? action, String? operationType, Map<String, dynamic>? parameters}) onUpdateImage;

  const BackgroundPanel({
    required this.image,
    required this.imageId,
    required this.onCancel,
    required this.onApply,
    required this.onUpdateImage,
    super.key,
  });

  @override
  _BackgroundPanelState createState() => _BackgroundPanelState();
}

class _BackgroundPanelState extends State<BackgroundPanel> {
  Uint8List? _currentImage;

  @override
  void initState() {
    super.initState();
    _currentImage = widget.image;
  }

  void _navigateToPage(Widget page) async {
    try {
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      }
    } catch (e) {
      final localizations = AppLocalizations.of(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations?.error ?? 'Error'}: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(localizations),
            Expanded(
              child: Center(
                child: _currentImage != null
                    ? Image.memory(_currentImage!, fit: BoxFit.contain)
                    : Text(
                  localizations?.noImages ?? 'No image provided',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            _buildOptions(localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AppLocalizations? localizations) {
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.7),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.redAccent),
        onPressed: widget.onCancel,
        tooltip: localizations?.cancel ?? 'Cancel',
      ),
      title: Text(
        localizations?.backgroundEditing ?? 'Background Editing',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildOptions(AppLocalizations? localizations) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      color: Colors.grey[900],
      child: Column(
        children: [
          _buildOptionButton(
            localizations?.removeBackground ?? 'Remove Background',
            Icons.delete,
                () => _navigateToPage(
              RemoveBackgroundPage(
                image: widget.image,
                imageId: widget.imageId,
                onCancel: () => Navigator.pop(context),
                onApply: (newImage) {
                  setState(() => _currentImage = newImage);
                  widget.onApply(newImage);
                  Navigator.pop(context);
                },
                onUpdateImage: widget.onUpdateImage,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionButton(
            localizations?.blurBackground ?? 'Blur Background',
            Icons.blur_on,
                () => _navigateToPage(
              BlurBackgroundPage(
                image: widget.image,
                imageId: widget.imageId,
                onCancel: () => Navigator.pop(context),
                onApply: (newImage) {
                  setState(() => _currentImage = newImage);
                  widget.onApply(newImage);
                  Navigator.pop(context);
                },
                onUpdateImage: widget.onUpdateImage,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionButton(
            localizations?.changeBackground ?? 'Change Background',
            Icons.image,
                () => _navigateToPage(
              ChangeBackgroundPage(
                image: widget.image,
                imageId: widget.imageId,
                onCancel: () => Navigator.pop(context),
                onApply: (newImage) {
                  setState(() => _currentImage = newImage);
                  widget.onApply(newImage);
                  Navigator.pop(context);
                },
                onUpdateImage: widget.onUpdateImage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String title, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }
}