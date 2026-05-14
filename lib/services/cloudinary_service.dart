import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  static const String _cloudName = 'dtqmccyn5';
  static const String _uploadPreset = 'ml_default';

  Future<String?> uploadFile(File file) async {
    try {
      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$_cloudName/auto/upload');

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final result = json.decode(String.fromCharCodes(responseData));

      if (response.statusCode == 200) {
        return result['secure_url'] as String;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}