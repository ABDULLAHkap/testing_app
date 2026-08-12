import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_client.dart';

class ExamCategoryService {
  final ApiClient _api = ApiClient();

  Future<void> updateCategory(String targetExam) async {
    final baseUrl = await _api.getBaseUrl();
    final token = await _api.getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/auth/exam-category'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'target_exam': targetExam}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Could not change exam category';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['detail'] != null) {
          message = body['detail'].toString();
        }
      } catch (_) {}
      throw ApiException(response.statusCode, message);
    }
  }
}
