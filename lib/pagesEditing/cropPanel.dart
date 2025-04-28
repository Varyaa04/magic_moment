// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
// import 'package:pro_image_editor/pro_image_editor.dart';
//
// class CropPanel extends StatefulWidget {
//   final Uint8List originalImage;
//   final VoidCallback onCancel;
//   final Function(Uint8List) onApply;
//   final ValueChanged<double> onCropTypeSelected;
//   final double? currentPreset;
//
//   const CropPanel({
//     required this.originalImage,
//     required this.onCancel,
//     required this.onApply,
//     required this.onCropTypeSelected,
//     this.currentPreset,
//     Key? key,
//   }) : super(key: key);
//
//   @override
//   _CropPanelState createState() => _CropPanelState();
// }
//
// class _CropPanelState extends State<CropPanel> {
//   late double _selectedPreset;
//   bool _isProcessing = false;
//   final _editorKey = GlobalKey<ProImageEditorState>();
//
//   @override
//   void initState() {
//     super.initState();
//     _selectedPreset = widget.currentPreset ?? 1.0;
//   }
//
//   Future<void> _performCrop() async {
//     if (_isProcessing) return;
//
//     setState(() {
//       _isProcessing = true;
//     });
//
//     try {
//       final editedImage = await _editorKey.currentState?.getEditedImage();
//       if (editedImage != null) {
//         widget.onApply(editedImage);
//       }
//     } catch (e) {
//       debugPrint('Error cropping image: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error cropping image: ${e.toString()}')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isProcessing = false;
//         });
//       }
//     }
//   }
//
//   void _setAspectRatio(double ratio) {
//     setState(() {
//       _selectedPreset = ratio;
//     });
//     _editorKey.currentState?.cropRotateEditor.setAspectRatio(ratio);
//     widget.onCropTypeSelected(ratio);
//   }
//
//   void _setFreeCrop() {
//     _editorKey.currentState?.cropRotateEditor.setFreeCrop();
//     widget.onCropTypeSelected(0);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final appLocalizations = AppLocalizations.of(context);
//
//     final cropOptions = [
//       _CropOption(
//         icon: Icons.crop_free,
//         label: appLocalizations?.freeCrop ?? 'Free',
//         preset: 0,
//       ),
//       _CropOption(
//         icon: Icons.crop_16_9,
//         label: '16:9',
//         preset: 16/9,
//       ),
//       _CropOption(
//         icon: Icons.crop_3_2,
//         label: '3:2',
//         preset: 3/2,
//       ),
//       _CropOption(
//         icon: Icons.crop_din,
//         label: '1:1',
//         preset: 1,
//       ),
//       _CropOption(
//         icon: Icons.crop_portrait,
//         label: appLocalizations?.portraitCrop ?? 'Portrait',
//         preset: 4/5,
//       ),
//     ];
//
//     return Column(
//       children: [
//         Expanded(
//           child: ProImageEditor.memory(
//             widget.originalImage,
//             key: _editorKey,
//             configs: const ProImageEditorConfigs(
//               cropRotateEditorConfigs: CropRotateEditorConfigs(),
//             ),
//             callbacks: ProImageEditorCallbacks(
//               onImageEditingComplete: (bytes) {},
//               onCloseEditor: () {},
//             ),
//           ),
//         ),
//         Container(
//           height: 130,
//           decoration: BoxDecoration(
//             color: Colors.grey[900],
//             borderRadius: BorderRadius.circular(10),
//           ),
//           padding: const EdgeInsets.all(8),
//           child: Column(
//             children: [
//               SizedBox(
//                 height: 60,
//                 child: ListView.builder(
//                   scrollDirection: Axis.horizontal,
//                   itemCount: cropOptions.length,
//                   itemBuilder: (context, index) {
//                     final option = cropOptions[index];
//                     final isSelected = _selectedPreset == option.preset;
//
//                     return Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 8),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           IconButton(
//                             icon: Icon(
//                               option.icon,
//                               color: isSelected ? Colors.blue : Colors.white,
//                             ),
//                             onPressed: () {
//                               if (option.preset == 0) {
//                                 _setFreeCrop();
//                               } else {
//                                 _setAspectRatio(option.preset);
//                               }
//                             },
//                           ),
//                           Text(
//                             option.label,
//                             style: TextStyle(
//                               color: isSelected ? Colors.blue : Colors.white,
//                               fontSize: 10,
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.only(top: 8),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     TextButton(
//                       onPressed: _isProcessing ? null : widget.onCancel,
//                       child: Text(
//                         appLocalizations?.cancel ?? 'Cancel',
//                         style: const TextStyle(color: Colors.white),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     TextButton(
//                       onPressed: _isProcessing ? null : _performCrop,
//                       child: _isProcessing
//                           ? const SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       )
//                           : Text(
//                         appLocalizations?.save ?? 'Apply',
//                         style: const TextStyle(color: Colors.white),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// class _CropOption {
//   final IconData icon;
//   final String label;
//   final double preset;
//
//   _CropOption({
//     required this.icon,
//     required this.label,
//     required this.preset,
//   });
// }