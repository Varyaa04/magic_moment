import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:MagicMoment/themeWidjets/formatButtonIcon.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'package:MagicMoment/database/magicMomentDatabase.dart';

class FormatSetPage extends StatefulWidget {
  const FormatSetPage({super.key});

  @override
  _FormatSetPageState createState() => _FormatSetPageState();
}

class _FormatSetPageState extends State<FormatSetPage> {
  String? _selectedFormat;
  final List<String> _formats = ['PNG', 'JPEG'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedFormat();
  }

  Future<void> _loadSavedFormat() async {
    try {
      final db = magicMomentDatabase.instance;
      final format = await db.getImageFormat();
      setState(() {
        _selectedFormat = format ?? 'PNG'; // По умолчанию PNG
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading image format: $e');
      setState(() {
        _selectedFormat = 'PNG';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveFormatToDatabase(String format) async {
    try {
      final db = magicMomentDatabase.instance;
      await db.setImageFormat(format);
      setState(() {
        _selectedFormat = format;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Format saved: $format')),
      );
    } catch (e) {
      debugPrint('Error saving image format: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save format: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
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
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(FluentIcons.arrow_left_16_filled),
                      color: colorScheme.onSurface,
                      iconSize: 30,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              child: Text(
                appLocalizations.format,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Oi-Regular',
                  fontSize: 26,
                  color: colorScheme.onSecondary,
                  fontWeight: FontWeight.w100,
                ),
              ),
            ),
            const SizedBox(height: 40),
            _isLoading
                ? const CircularProgressIndicator()
                : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: DropdownButtonFormField<String>(
                value: _selectedFormat,
                decoration: InputDecoration(
                  labelText: appLocalizations.selectFormat,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: _formats.map((String format) {
                  return DropdownMenuItem<String>(
                    value: format,
                    child: Text(format),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _saveFormatToDatabase(newValue);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}