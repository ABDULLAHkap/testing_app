import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty && NotificationService.isConfigured) {
    await Firebase.initializeApp(options: NotificationService.options);
  }
}

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();
  final ApiClient _api = ApiClient();
  String? _token;

  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const _vapidKey = String.fromEnvironment('FIREBASE_WEB_VAPID_KEY');

  static bool get isConfigured =>
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _senderId.isNotEmpty &&
      _projectId.isNotEmpty;

  static FirebaseOptions get options => FirebaseOptions(
    apiKey: _apiKey,
    appId: _appId,
    messagingSenderId: _senderId,
    projectId: _projectId,
    storageBucket: _storageBucket.isEmpty ? null : _storageBucket,
  );

  static Future<void> bootstrap() async {
    if (!isConfigured) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options);
      }
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (error) {
      debugPrint('Notification bootstrap skipped: $error');
    }
  }

  Future<bool> registerForSignedInUser() async {
    if (!isConfigured || Firebase.apps.isEmpty) return false;
    try {
      final messaging = FirebaseMessaging.instance;
      final permission = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (permission.authorizationStatus == AuthorizationStatus.denied) {
        return false;
      }
      _token = await messaging.getToken(
        vapidKey: kIsWeb && _vapidKey.isNotEmpty ? _vapidKey : null,
      );
      if (_token == null) return false;
      await _register(_token!);
      messaging.onTokenRefresh.listen((token) {
        _token = token;
        _register(token).catchError((_) {});
      });
      return true;
    } catch (error) {
      debugPrint('Notification registration skipped: $error');
      return false;
    }
  }

  Future<void> _register(String token) => _api.registerPushDevice(
    token: token,
    platform: kIsWeb
        ? 'web'
        : defaultTargetPlatform == TargetPlatform.android
        ? 'android'
        : defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : defaultTargetPlatform.name,
  );
}
