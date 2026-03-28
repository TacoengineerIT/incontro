import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  static Future<void> showMatchNotification(String name) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'match_channel',
        'Match',
        channelDescription: 'Notifiche per nuovi match',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🎉 Nuovo Match!',
      'Hai fatto match con $name! Digli ciao 👋',
      details,
    );
  }

  static Future<void> showStudySessionNotification(
      String locationName) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'study_channel',
        'Sessione Studio',
        channelDescription: 'Notifiche sessioni di studio',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.show(
      1,
      '📚 Sessione avviata',
      'Stai studiando a $locationName. In bocca al lupo! 🍀',
      details,
    );
  }
}
