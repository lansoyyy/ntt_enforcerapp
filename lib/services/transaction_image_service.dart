import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:enforcer_app/network/endpoints.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class TransactionImageService {
  final GetStorage _box = GetStorage();

  Map<String, String> _headers() {
    final token = _box.read('token');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> getImages({
    required String transactionId,
    required String type,
  }) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}transaction-images').replace(
      queryParameters: {
        'transaction_id': transactionId,
        'type': type,
      },
    );

    final response = await http.get(url, headers: _headers());

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final data = decoded['data'];
      if (data is List) return data;
      return [];
    }

    throw Exception('Failed to fetch transaction images: ${response.body}');
  }

  Future<Map<String, dynamic>> createImage({
    required String transactionId,
    required String type,
    required String base64,
  }) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}transaction-images');

    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'transaction_id': transactionId,
        'type': type,
        'base64': base64,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Failed to create transaction image: ${response.body}');
  }

  Future<void> deleteImage(int id) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}transaction-images/$id');

    final response = await http.delete(url, headers: _headers());

    if (response.statusCode == 200) {
      return;
    }

    throw Exception('Failed to delete transaction image: ${response.body}');
  }

  static Future<String> fileToResizedBase64DataUri(
    String filePath, {
    int maxDimension = 500,
    int jpegQuality = 85,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }

    final int maxSide = max(decoded.width, decoded.height);

    img.Image processed = decoded;

    if (maxSide > maxDimension) {
      final scale = maxDimension / maxSide;
      final newWidth = max(1, (decoded.width * scale).round());
      final newHeight = max(1, (decoded.height * scale).round());
      processed = img.copyResize(
        decoded,
        width: newWidth,
        height: newHeight,
      );
    }

    final resizedBytes = img.encodeJpg(processed, quality: jpegQuality);
    return 'data:image/jpeg;base64,${base64Encode(resizedBytes)}';
  }

  static Uint8List base64DataUriToBytes(String dataUri) {
    final String cleaned = dataUri.contains(',')
        ? dataUri.substring(dataUri.indexOf(',') + 1)
        : dataUri;

    return base64Decode(cleaned);
  }
}
