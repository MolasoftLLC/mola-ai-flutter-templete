import 'dart:io';

import 'package:http/http.Dart' as http;

class ImagePost {
  Future<void> imagePost(File imageFile, Uri url) async {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'multipart/form-data'},
      body: {'image': imageFile},
    );
  }
}
