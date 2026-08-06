import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'api_client.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  AuthStatus status = AuthStatus.unknown;
  UserModel? currentUser;
  String? lastError;
  Timer? _heartbeatTimer;

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _api.sendHeartbeat().catchError((_) {});
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _api.sendHeartbeat().catchError((_) {}),
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> tryAutoLogin() async {
    final token = await _api.getToken();
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      currentUser = await _api.getMe();
      status = AuthStatus.authenticated;
      _startHeartbeat();
    } catch (_) {
      // token expired/invalid
      await _api.clearToken();
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    lastError = null;
    try {
      await _api.login(username, password);
      currentUser = await _api.getMe();
      status = AuthStatus.authenticated;
      _startHeartbeat();
      notifyListeners();
      return true;
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String username,
    String email,
    String password,
    String gender,
    String phone,
    String targetExam,
  ) async {
    lastError = null;
    try {
      await _api.register(username, email, password, gender, phone, targetExam);
      return true;
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyEmail(String email, String code) async {
    lastError = null;
    try {
      await _api.verifyEmail(email, code);
      return true;
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendOtp(String email) async {
    lastError = null;
    try {
      await _api.resendOtp(email);
      return true;
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _stopHeartbeat();
    await _api.logout();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopHeartbeat();
    super.dispose();
  }

  /// Re-fetches the current user (e.g. after changing the username) so
  /// screens showing `currentUser.username` update immediately.
  Future<void> refreshUser() async {
    try {
      currentUser = await _api.getMe();
      notifyListeners();
    } catch (_) {
      // Non-fatal — the old cached user data just stays as-is.
    }
  }
}
