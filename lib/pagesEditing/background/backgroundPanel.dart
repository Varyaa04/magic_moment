import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:MagicMoment/pagesEditing/background/removeBackground.dart';
import 'package:MagicMoment/pagesEditing/background/changeBackground.dart';
import 'package:MagicMoment/pagesEditing/background/blurBackground.dart';
import '../../pagesSettings/classesSettings/app_localizations.dart';

class BackgroundPanel extends StatefulWidget {
  final Uint8List image;
  final int imageId;
  final VoidCallback onCancel;
  final Function(Uint8List) onApply;
  final Function(Uint8List,
      {String? action, String? operationType, Map<String, dynamic>? parameters})
  onUpdateImage;

  const BackgroundPanel({
    required this.image,
    required this.imageId,
    required this.onCancel,
    required this.onApply,
    required this.onUpdateImage,
    super.key,
  });

  @override
  State<BackgroundPanel> createState() => _BackgroundPanelState();
}

class _BackgroundPanelState extends State<BackgroundPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Center(
                child: Image.memory(
                  widget.image,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Error displaying image: $error');
                    return Center(
                      child: Text(
                        AppLocalizations.of(context)?.invalidImage ??
                            'Failed to load image',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ),
            _buildBottomPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final localizations = AppLocalizations.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 600;
    return AppBar(
      backgroundColor: Colors.black.withOpacity(0.7),
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.close,
          color: Colors.redAccent,
          size: isDesktop ? 28 : 24,
        ),
        onPressed: () {
          debugPrint('Canceling BackgroundPanel');
          widget.onCancel();
        },
        tooltip: localizations?.cancel ?? 'Cancel',
      ),
      title: Text(
        localizations?.background ?? 'Background',
        style: TextStyle(
          color: Colors.white,
          fontSize: isDesktop ? 20 : 16,
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    final localizations = AppLocalizations.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 600;
    return Container(
      height: isDesktop ? 100 : 80,
      padding: EdgeInsets.symmetric(
        vertical: isDesktop ? 12 : 6,
        horizontal: isDesktop ? 24 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildOptionButton(
            icon: Icons.delete,
            label: localizations?.removeBackground ?? 'Remove',
            onTap: () async {
              if (!mounted) return;
              debugPrint('Navigating to RemoveBackgroundPage');
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RemoveBackgroundPage(
                    image: widget.image,
                    imageId: widget.imageId,
                    onCancel: () => Navigator.pop(context),
                    onApply: (image) {
                      debugPrint('onApply called with image size: ${image.length} bytes');
                      Navigator.pop(context, image);
                    },
                    onUpdateImage: widget.onUpdateImage,
                  ),
                ),
              );
              debugPrint('Received result from RemoveBackgroundPage: ${result?.length ?? 'null'} bytes');
              if (!mounted || result == null || (result as Uint8List).isEmpty) {
                if (mounted) {
                  debugPrint('Error: Result is null or empty');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          localizations?.error ?? 'Error processing image'),
                      backgroundColor: Colors.red[700],
                    ),
                  );
                }
                return;
              }
              // Удаляем вызовы onUpdateImage и onApply, так как они уже выполнены в RemoveBackgroundPage
              debugPrint('Returning to EditPage with result');
            },
          ),
          _buildOptionButton(
            icon: Icons.image,
            label: localizations?.changeBackground ?? 'Change',
            onTap: () async {
              if (!mounted) return;
              debugPrint('Navigating to ChangeBackgroundPage');
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeBackgroundPage(
                    image: widget.image,
                    imageId: widget.imageId,
                    onCancel: () => Navigator.pop(context),
                    onApply: (image) {
                      debugPrint('onApply called with image size: ${image.length} bytes');
                      Navigator.pop(context, image);
                    },
                    onUpdateImage: widget.onUpdateImage,
                  ),
                ),
              );
              debugPrint('Received result from ChangeBackgroundPage: ${result?.length ?? 'null'} bytes');
              if (!mounted || result == null || (result as Uint8List).isEmpty) {
                if (mounted) {
                  debugPrint('Error: Result is null or empty');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          localizations?.error ?? 'Error processing image'),
                      backgroundColor: Colors.red[700],
                    ),
                  );
                }
                return;
              }
              // Удаляем вызовы onUpdateImage и onApply
              debugPrint('Returning to EditPage with result');
            },
          ),
          _buildOptionButton(
            icon: Icons.blur_on,
            label: localizations?.blurBackground ?? 'Blur',
            onTap: () async {
              if (!mounted) return;
              debugPrint('Navigating to BlurBackgroundPage');
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlurBackgroundPage(
                    image: widget.image,
                    imageId: widget.imageId,
                    onCancel: () => Navigator.pop(context),
                    onApply: (image) {
                      debugPrint('onApply called with image size: ${image.length} bytes');
                      Navigator.pop(context, image);
                    },
                    onUpdateImage: widget.onUpdateImage,
                  ),
                ),
              );
              debugPrint('Received result from BlurBackgroundPage: ${result?.length ?? 'null'} bytes');
              if (!mounted || result == null || (result as Uint8List).isEmpty) {
                if (mounted) {
                  debugPrint('Error: Result is null or empty');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          localizations?.error ?? 'Error processing image'),
                      backgroundColor: Colors.red[700],
                    ),
                  );
                }
                return;
              }
              // Удаляем вызовы onUpdateImage и onApply
              debugPrint('Returning to EditPage with result');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    return InkWell(
      onTap: () {
        if (!mounted) return;
        onTap();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: isDesktop ? 32 : 24,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: isDesktop ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }
}