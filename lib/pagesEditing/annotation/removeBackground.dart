import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

Future<File?> removeBackground(File imageFile, String apiKey) async {
  final url = Uri.parse("https://api.remove.bg/v1.0/removebg");

  final request = http.MultipartRequest("POST", url)
    ..headers['X-Api-Key'] = apiKey
    ..files.add(await http.MultipartFile.fromPath('image_file', imageFile.path))
    ..fields['size'] = 'auto';

  final response = await request.send();

  if (response.statusCode == 200) {
    final bytes = await response.stream.toBytes();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/no_bg.png');
    await file.writeAsBytes(bytes);
    return file;
  } else {
    print("Remove.bg error: ${response.statusCode}");
    return null;
  }
}
