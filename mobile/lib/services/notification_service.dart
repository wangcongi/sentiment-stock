import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> init() async {
    // 请求权限
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await _fcm.getToken();
      // TODO: 将token保存到Supabase alerts表
      print('FCM Token: $token');
    }

    // 前台消息处理
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // TODO: 展示本地通知
      print('Foreground message: ${message.notification?.title}');
    });

    // 点击通知打开App
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // TODO: 导航到对应帖子详情
    });
  }
}
