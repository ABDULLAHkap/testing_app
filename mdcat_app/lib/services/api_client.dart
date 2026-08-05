import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/models.dart';

/// Thrown for any non-2xx response so screens can show a real error
/// message instead of a generic crash.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  // Override this at build time for release builds:
  // flutter build apk --dart-define=API_BASE_URL=https://your-api.onrender.com
  static const String _defaultBaseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "http://10.0.2.2:8000",
  );
  static const _baseUrlKey = "custom_base_url";

  static String? _cachedBaseUrl;

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = "auth_token";

  /// The backend URL currently in use. Change it at runtime via
  /// [setBaseUrl] (e.g. from a Server Settings screen) — no rebuild
  /// needed when your local IP changes or when you switch to a deployed
  /// backend URL.
  Future<String> getBaseUrl() async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;
    final stored = await _storage.read(key: _baseUrlKey);
    _cachedBaseUrl = stored ?? _defaultBaseUrl;
    return _cachedBaseUrl!;
  }

  Future<void> setBaseUrl(String url) async {
    final cleaned = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    await _storage.write(key: _baseUrlKey, value: cleaned);
    _cachedBaseUrl = cleaned;
  }

  Future<void> _saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  dynamic _decodeOrThrow(http.Response resp) {
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (resp.body.isEmpty) return null;
      return jsonDecode(resp.body);
    }
    String message = "Something went wrong (${resp.statusCode})";
    try {
      final body = jsonDecode(resp.body);
      if (body is Map && body["detail"] != null) {
        message = body["detail"].toString();
      }
    } catch (_) {}
    throw ApiException(resp.statusCode, message);
  }

  // ---------------- Auth ----------------

  Future<void> register(
    String username,
    String email,
    String password,
    String gender,
    String phone,
    String targetExam,
  ) async {
    final baseUrl = await getBaseUrl();
    final resp = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "email": email,
        "password": password,
        "gender": gender,
        "phone": phone,
        "target_exam": targetExam,
      }),
    );
    _decodeOrThrow(resp);
  }

  Future<void> verifyEmail(String email, String code) async {
    final baseUrl = await getBaseUrl();
    final resp = await http.post(
      Uri.parse("$baseUrl/auth/verify-email"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "code": code}),
    );
    _decodeOrThrow(resp);
  }

  Future<void> resendOtp(String email) async {
    final baseUrl = await getBaseUrl();
    final resp = await http.post(
      Uri.parse("$baseUrl/auth/resend-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
    _decodeOrThrow(resp);
  }

  Future<void> requestPasswordReset(String email) async {
    final baseUrl = await getBaseUrl();
    final resp = await http.post(
      Uri.parse("$baseUrl/auth/forgot-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
    _decodeOrThrow(resp);
  }

  Future<void> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    final baseUrl = await getBaseUrl();
    final resp = await http.post(
      Uri.parse("$baseUrl/auth/reset-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "code": code,
        "new_password": newPassword,
      }),
    );
    _decodeOrThrow(resp);
  }

  Future<void> login(String username, String password) async {
    final baseUrl = await getBaseUrl();
    final resp = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {"username": username, "password": password},
    );
    final data = _decodeOrThrow(resp);
    await _saveToken(data["access_token"]);
  }

  Future<UserModel> getMe() async {
    final baseUrl = await getBaseUrl();
    final resp = await http.get(
      Uri.parse("$baseUrl/auth/me"),
      headers: await _authHeaders(),
    );
    final data = _decodeOrThrow(resp);
    return UserModel.fromJson(data);
  }

  Future<void> logout() async {
    await clearToken();
  }

  Future<UserModel> setExamDate(DateTime examDate) async {
    final baseUrl = await getBaseUrl();
    final resp = await http.put(
      Uri.parse("$baseUrl/auth/exam-date"),
      headers: {
        "Content-Type": "application/json",
        ...await _authHeaders(),
      },
      body: jsonEncode({"exam_date": examDate.toIso8601String()}),
    );
    final data = _decodeOrThrow(resp);
    return UserModel.fromJson(data);
  }

  Future<UserModel> updateUsername(String newUsername) async {
    final baseUrl = await getBaseUrl();
    final resp = await http.put(
      Uri.parse("$baseUrl/auth/username"),
      headers: {
        "Content-Type": "application/json",
        ...await _authHeaders(),
      },
      body: jsonEncode({"username": newUsername}),
    );
    final data = _decodeOrThrow(resp);
    return UserModel.fromJson(data);
  }

  // ---------------- Dashboard ----------------

  Future<DashboardStats> getDashboard() async {
    final baseUrl = await getBaseUrl();
    final resp = await http.get(
      Uri.parse("$baseUrl/dashboard"),
      headers: await _authHeaders(),
    );
    final data = _decodeOrThrow(resp);
    return DashboardStats.fromJson(data);
  }

  // ---------------- MCQ generation ----------------

  /// Generates MCQs. Leave `text` null for the default no-upload flow —
  /// the AI generates questions for the signed-in user's selected exam for
  /// the given subject/topic. Pass `text` only if grounding questions in
  /// uploaded material (legacy upload flow).
  Future<QuizSet> generateMcqs({
    required int numberOfQuestions,
    required String subject,
    required String difficulty,
    required int quizMinutes,
    String? topic,
    String? text,
    String? sourceFilename,
  }) async {
    final baseUrl = await getBaseUrl();
    final resp = await http.post(
      Uri.parse("$baseUrl/mcqs/generate"),
      headers: {
        "Content-Type": "application/json",
        ...await _authHeaders(),
      },
      body: jsonEncode({
        if (text != null) "text": text,
        "number_of_questions": numberOfQuestions,
        "subject": subject,
        if (topic != null) "topic": topic,
        "difficulty": difficulty,
        "quiz_minutes": quizMinutes,
        "source_filename": sourceFilename,
      }),
    );
    final data = _decodeOrThrow(resp);
    return QuizSet.fromJson(data);
  }

  Future<List<TopicListItem>> getSubjects() async {
    final baseUrl = await getBaseUrl();
    final resp = await http.get(
      Uri.parse("$baseUrl/mcqs/subjects"),
      headers: await _authHeaders(),
    );
    final data = _decodeOrThrow(resp) as List;
    return data.map((e) => TopicListItem.fromJson(e)).toList();
  }

  Future<QuizSet> generateMockTest({
    required int totalQuestions,
    required String difficulty,
    required int quizMinutes,
  }) async {
    final baseUrl = await getBaseUrl();
    final resp = await http.post(
      Uri.parse("$baseUrl/mcqs/mock-test"),
      headers: {
        "Content-Type": "application/json",
        ...await _authHeaders(),
      },
      body: jsonEncode({
        "total_questions": totalQuestions,
        "difficulty": difficulty,
        "quiz_minutes": quizMinutes,
      }),
    );
    final data = _decodeOrThrow(resp);
    return QuizSet.fromJson(data);
  }

  // ---------------- Past Papers ----------------

  Future<List<PastPaperSummary>> getPastPapers() async {
    final baseUrl = await getBaseUrl();
    final resp = await http.get(
      Uri.parse("$baseUrl/mcqs/past-papers"),
      headers: await _authHeaders(),
    );
    final data = _decodeOrThrow(resp) as List;
    return data.map((e) => PastPaperSummary.fromJson(e)).toList();
  }

  Future<PastPaperDetail> getPastPaperDetail(String paperId) async {
    final baseUrl = await getBaseUrl();
    final resp = await http.get(
      Uri.parse("$baseUrl/mcqs/past-papers/$paperId"),
      headers: await _authHeaders(),
    );
    final data = _decodeOrThrow(resp);
    return PastPaperDetail.fromJson(data);
  }

  Future<QuizSet> generateFromPastPaper(String paperId) async {
    final baseUrl = await getBaseUrl();
    final resp = await http.post(
      Uri.parse("$baseUrl/mcqs/past-papers/$paperId/generate"),
      headers: await _authHeaders(),
    );
    final data = _decodeOrThrow(resp);
    return QuizSet.fromJson(data);
  }

  Future<List<QuizSetSummary>> listQuizSets() async {
    final baseUrl = await getBaseUrl();
    final resp = await http.get(
      Uri.parse("$baseUrl/mcqs"),
      headers: await _authHeaders(),
    );
    final data = _decodeOrThrow(resp) as List;
    return data.map((e) => QuizSetSummary.fromJson(e)).toList();
  }

  Future<QuizSet> getQuizSet(int id) async {
    final baseUrl = await getBaseUrl();
    final resp = await http.get(
      Uri.parse("$baseUrl/mcqs/$id"),
      headers: await _authHeaders(),
    );
    final data = _decodeOrThrow(resp);
    return QuizSet.fromJson(data);
  }

  // ---------------- Quiz attempts ----------------

  Future<AttemptResult> startAttempt(int quizSetId) async {
    final baseUrl = await getBaseUrl();
    final resp = await http.post(
      Uri.parse("$baseUrl/quiz/$quizSetId/start"),
      headers: await _authHeaders(),
    );
    final data = _decodeOrThrow(resp);
    return AttemptResult.fromJson(data);
  }

  Future<AttemptResult> submitAttempt(
    int attemptId,
    Map<int, String> answers,
  ) async {
    final baseUrl = await getBaseUrl();
    final answersJson = answers.map((k, v) => MapEntry(k.toString(), v));
    final resp = await http.post(
      Uri.parse("$baseUrl/quiz/attempts/$attemptId/submit"),
      headers: {
        "Content-Type": "application/json",
        ...await _authHeaders(),
      },
      body: jsonEncode({"answers": answersJson}),
    );
    final data = _decodeOrThrow(resp);
    return AttemptResult.fromJson(data);
  }

  Future<AttemptResult> getAttempt(int attemptId) async {
    final baseUrl = await getBaseUrl();
    final resp = await http.get(
      Uri.parse("$baseUrl/quiz/attempts/$attemptId"),
      headers: await _authHeaders(),
    );
    final data = _decodeOrThrow(resp);
    return AttemptResult.fromJson(data);
  }

  /// Returns raw PDF bytes; caller decides whether to save/share/open it.
  Future<List<int>> downloadResultPdf(int attemptId) async {
    final baseUrl = await getBaseUrl();
    final resp = await http.get(
      Uri.parse("$baseUrl/quiz/attempts/$attemptId/pdf"),
      headers: await _authHeaders(),
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, "Could not download result PDF");
    }
    return resp.bodyBytes;
  }

  // ---------------- Progress ----------------

  Future<List<ProgressPoint>> getProgress() async {
    final baseUrl = await getBaseUrl();
    final resp = await http.get(
      Uri.parse("$baseUrl/progress"),
      headers: await _authHeaders(),
    );
    final data = _decodeOrThrow(resp) as List;
    return data.map((e) => ProgressPoint.fromJson(e)).toList();
  }

  // ---------------- Admin ----------------

  Future<Map<String, dynamic>> getAdminOverview() async {
    final baseUrl = await getBaseUrl();
    final resp = await http.get(
      Uri.parse("$baseUrl/admin/overview"),
      headers: await _authHeaders(),
    );
    return Map<String, dynamic>.from(_decodeOrThrow(resp));
  }

  Future<List<Map<String, dynamic>>> getAdminUsers() async {
    final baseUrl = await getBaseUrl();
    final resp = await http.get(
      Uri.parse("$baseUrl/admin/users"),
      headers: await _authHeaders(),
    );
    final data = _decodeOrThrow(resp) as List;
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<void> grantSubscription(int userId, {int days = 30}) async {
    final baseUrl = await getBaseUrl();
    final resp = await http.post(
      Uri.parse("$baseUrl/admin/users/$userId/subscription"),
      headers: {"Content-Type": "application/json", ...await _authHeaders()},
      body: jsonEncode({"days": days}),
    );
    _decodeOrThrow(resp);
  }
}
