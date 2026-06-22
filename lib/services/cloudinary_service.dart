import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String _cloudName = "dbiiml5iy";
  static const String _uploadPreset = "image_chat";

  /// Uploads an image from XFile and returns its secure URL.
  static Future<String?> uploadImage(XFile imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      var uri = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/image/upload");
      var request = http.MultipartRequest("POST", uri);
      request.files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: imageFile.name));
      request.fields['upload_preset'] = _uploadPreset;

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        var result = String.fromCharCodes(responseData);
        return jsonDecode(result)['secure_url'];
      } else {
        throw Exception("فشل رفع الصورة لـ Cloudinary");
      }
    } catch (e) {
      print("Cloudinary Error: $e");
      return null;
    }
  }
}
