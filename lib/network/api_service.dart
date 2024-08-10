import 'dart:convert';
import 'package:enforcer_app/network/endpoints.dart';
import 'package:http/http.dart' as http;

class Network {



  Future<http.Response> get(String endpoint) async {
   
    final url = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    final response = await http.get(url);
    _checkStatusCode(response);
  
    return response;
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    _checkStatusCode(response);
    return response;
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    _checkStatusCode(response);
    return response;
  }

  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
    final response = await http.delete(url);
    _checkStatusCode(response);
    return response;
  }

  void _checkStatusCode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed request: ${response.statusCode}');
    }
  }
}
