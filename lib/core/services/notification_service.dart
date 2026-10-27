import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  NotificationService._init();

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // Create Notification Channel for Android
    const androidChannel = AndroidNotificationChannel(
      'my_gym_alerts',
      'تنبيهات MY GYM',
      description: 'إشعارات الاشتراكات المنتهية ومتابعة غياب الأعضاء',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(androidChannel);
      await androidImplementation.requestNotificationsPermission();
    }

    _isInitialized = true;
  }

  /// Sends an instant local notification to the gym owner
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'my_gym_alerts',
      'تنبيهات MY GYM',
      channelDescription: 'إشعارات الاشتراكات المنتهية ومتابعة غياب الأعضاء',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  /// Checks gym alerts and sends summary notification to captain
  Future<void> sendDailySummaryNotification({
    required int expiringCount,
    required int expiredCount,
    required int absentCount,
  }) async {
    final total = expiringCount + expiredCount + absentCount;
    if (total == 0) return;

    final List<String> parts = [];
    if (expiredCount > 0) parts.add('$expiredCount منتهي');
    if (expiringCount > 0) parts.add('$expiringCount قارب على الانتهاء');
    if (absentCount > 0) parts.add('$absentCount غائب');

    final body = 'لديك اليوم: ${parts.join('، ')}. اضغط للمتابعة والتواصل مع المشتركين.';

    await showNotification(
      id: 101,
      title: 'MY GYM 🔔 تنبيهات المتابعة اليومية',
      body: body,
    );
  }
}
