import 'package:flutter/material.dart';
import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
import 'package:image_cropper/image_cropper.dart';

class CropPanel extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onApply;
  final ValueChanged<CropAspectRatioPreset> onCropTypeSelected;
  final CropAspectRatioPreset? currentPreset;

  const CropPanel({
    required this.onCancel,
    required this.onApply,
    required this.onCropTypeSelected,
    this.currentPreset,
    Key? key,
  }) : super(key: key);

  @override
  _CropPanelState createState() => _CropPanelState();
}

class _CropPanelState extends State<CropPanel> {
  late CropAspectRatioPreset _selectedPreset;

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.currentPreset ?? CropAspectRatioPreset.original;
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);

    final cropOptions = [
      _CropOption(
        icon: Icons.crop_free,
        label: appLocalizations?.freeCrop ?? 'Свободная',
        preset: CropAspectRatioPreset.original,
      ),
      _CropOption(
        icon: Icons.crop_16_9,
        label: '16:9',
        preset: CropAspectRatioPreset.ratio16x9,
      ),
      _CropOption(
        icon: Icons.crop_3_2,
        label: '3:2',
        preset: CropAspectRatioPreset.ratio3x2,
      ),
      _CropOption(
        icon: Icons.crop_din,
        label: '1:1',
        preset: CropAspectRatioPreset.square,
      ),
      _CropOption(
        icon: Icons.crop_portrait,
        label: appLocalizations?.portraitCrop ?? 'Портрет',
        preset: CropAspectRatioPreset.ratio5x4,
      ),
      _CropOption(
        icon: Icons.rotate_90_degrees_cw,
        label: appLocalizations?.rotateCrop ?? 'Поворот',
        preset: CropAspectRatioPreset.original,
      ),
    ];

    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Crop options
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: cropOptions.length,
              itemBuilder: (context, index) {
                final option = cropOptions[index];
                final isSelected = _selectedPreset == option.preset;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          option.icon,
                          color: isSelected ? Colors.blue : Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedPreset = option.preset;
                          });
                          widget.onCropTypeSelected(option.preset);
                        },
                      ),
                      Text(
                        option.label,
                        style: TextStyle(
                          color: isSelected ? Colors.blue : Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    widget.onCancel();
                    Navigator.of(context).pop(); // Добавляем закрытие панели
                  },
                  child: Text(
                    appLocalizations?.cancel ?? 'Отмена',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () {
                    widget.onApply();
                    Navigator.of(context).pop(); // Добавляем закрытие панели
                  },
                  child: Text(
                    appLocalizations?.save ?? 'Применить',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CropOption {
  final IconData icon;
  final String label;
  final CropAspectRatioPreset preset;

  _CropOption({
    required this.icon,
    required this.label,
    required this.preset,
  });
}