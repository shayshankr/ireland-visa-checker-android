import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static const _channelId = 'visa_decisions';
  static const _channelName = 'Visa Decision Alerts';
  static const _channelDesc = 'Notified when your visa decision is published';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
    );
    await _createChannel(_plugin);
  }

  static Future<void> _createChannel(
      FlutterLocalNotificationsPlugin plugin) async {
    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      ),
    );
  }

  static Future<bool> requestPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await androidPlugin?.requestNotificationsPermission() ?? true;
  }

  static Future<void> showDecisionFound({
    required String number,
    required String decision,
    required String embassy,
  }) async {
    final isApproved = decision.toUpperCase() == 'APPROVED';
    await _plugin.show(
      number.hashCode.abs() % 100000,
      isApproved ? 'Visa Approved!' : 'Visa Decision Published',
      'IRL$number: $decision at $embassy',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  // Used from background isolate (workmanager) — creates its own plugin instance.
  static Future<void> showFromBackground({
    required String number,
    required String decision,
    required String embassy,
  }) async {
    final plugin = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(
        const InitializationSettings(android: androidInit));
    await _createChannel(plugin);

    final isApproved = decision.toUpperCase() == 'APPROVED';
    await plugin.show(
      number.hashCode.abs() % 100000,
      isApproved ? 'Visa Approved!' : 'Visa Decision Published',
      'IRL$number: $decision at $embassy',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
