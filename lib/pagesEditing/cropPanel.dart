// import 'package:flutter/material.dart';
// import 'package:MagicMoment/pagesSettings/classesSettings/app_localizations.dart';
// import 'package:image_cropper/image_cropper.dart';
//
// class CropPanel extends StatelessWidget {
//   final VoidCallback onCancel;
//   final VoidCallback onApply;
//   final ValueChanged<CropAspectRatioPreset> onCropTypeSelected;
//   final CropAspectRatioPreset? currentPreset;
//
//   const CropPanel({
//     required this.onCancel,
//     required this.onApply,
//     required this.onCropTypeSelected,
//     this.currentPreset,
//     Key? key,
//   }) : super(key: key);
//
//
//   @override
//   Widget build(BuildContext context) {
//     final appLocalizations = AppLocalizations.of(context);
//
//     // Список доступных вариантов обрезки
//     final cropOptions = [
//       _CropOption(
//         icon: Icons.crop_free,
//         label: appLocalizations?.freeCrop ?? 'Свободная',
//         preset: CropAspectRatioPreset.original,
//       ),
//       _CropOption(
//         icon: Icons.crop_16_9,
//         label: '16:9',
//         preset: CropAspectRatioPreset.ratio16x9,
//       ),
//       _CropOption(
//         icon: Icons.crop_3_2,
//         label: '3:2',
//         preset: CropAspectRatioPreset.ratio3x2,
//       ),
//       _CropOption(
//         icon: Icons.crop_din,
//         label: '1:1',
//         preset: CropAspectRatioPreset.square,
//       ),
//       _CropOption(
//         icon: Icons.crop_portrait,
//         label: appLocalizations?.portraitCrop ?? 'Портрет',
//         preset: CropAspectRatioPreset.ratio5x4,
//       ),
//       _CropOption(
//         icon: Icons.crop_rotate,
//         label: appLocalizations?.rotateCrop ?? 'Поворот',
//         preset: CropAspectRatioPreset.original,
//       ),
//     ];
//
//     return Container(
//       height: 130,
//       decoration: BoxDecoration(
//         color: Colors.grey[900],
//         borderRadius: BorderRadius.circular(10),
//       ),
//       padding: const EdgeInsets.all(8),
//       child: Column(
//         children: [
//           // Панель с вариантами обрезки
//           SizedBox(
//             height: 60,
//             child: ListView.builder(
//               scrollDirection: Axis.horizontal,
//               itemCount: cropOptions.length,
//               itemBuilder: (context, index) {
//                 final option = cropOptions[index];
//                 return Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 8),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       IconButton(
//                         icon: Icon(option.icon, color: Colors.white),
//                         onPressed: () => onCropTypeSelected(option.preset),
//                       ),
//                       Text(
//                         option.label,
//                         style: const TextStyle(color: Colors.white, fontSize: 10),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),
//
//           // Кнопки подтверждения/отмены
//           Padding(
//             padding: const EdgeInsets.only(top: 8),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 TextButton(
//                   onPressed: onCancel,
//                   child: Text(
//                     appLocalizations?.cancel ?? 'Отмена',
//                     style: const TextStyle(color: Colors.white),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 TextButton(
//                   onPressed: onApply,
//                   child: Text(
//                     appLocalizations?.save ?? 'Применить',
//                     style: const TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // Вспомогательный класс для хранения данных о вариантах обрезки
// class _CropOption {
//   final IconData icon;
//   final String label;
//   final CropAspectRatioPreset preset;
//
//   _CropOption({
//     required this.icon,
//     required this.label,
//     required this.preset,
//   });
// }