import 'package:sqflite/sql.dart';

class formatImage{
  final int idFormatImage;
  final String nameFormat;

  const formatImage({required this.idFormatImage, required this.nameFormat});

  Map<String, Object?> toMap(){
    return {'idFormatImage': idFormatImage, 'nameFormat': nameFormat};
  }

  @override
  String toString() {
    return 'formatImage{idFormatImage: $idFormatImage, nameFormat: $nameFormat}';
  }
}