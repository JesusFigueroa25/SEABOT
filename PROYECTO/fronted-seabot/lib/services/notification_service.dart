import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const String _notificationsEnabledKey = 'notifications_enabled';

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _notifications.initialize(settings);

    tz.initializeTimeZones();

    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));
  }

  static Future<bool> getNotificationsPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? false;
  }

  static Future<void> setNotificationsPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  static Future<bool> areNotificationsAllowed() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return true;

    return await androidPlugin.areNotificationsEnabled() ?? false;
  }

  static Future<bool> requestNotificationPermission() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return true;

    final granted = await androidPlugin.requestNotificationsPermission();
    if (granted == true) return true;

    return await areNotificationsAllowed();
  }

  static Future<bool> syncNotificationPreferenceWithPermission({
    bool rescheduleIfEnabled = false,
  }) async {
    final preferenceEnabled = await getNotificationsPreference();

    if (!preferenceEnabled) {
      await cancelDailyNotifications();
      return false;
    }

    final permissionGranted = await areNotificationsAllowed();
    if (!permissionGranted) {
      await setNotificationsPreference(false);
      await cancelDailyNotifications();
      return false;
    }

    if (rescheduleIfEnabled) {
      await scheduleDefaultDailyNotifications();
    }

    return true;
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    if (!await areNotificationsAllowed()) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'main_channel',
        'Notificaciones generales',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.show(0, title, body, details);
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  static Future<void> restoreScheduledNotificationsIfEnabled() async {
    final enabled = await syncNotificationPreferenceWithPermission(
      rescheduleIfEnabled: true,
    );

    if (enabled) {
      debugPrint('Notificaciones restauradas automaticamente');
    } else {
      debugPrint('Notificaciones desactivadas, no se restauran');
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final scheduledDate = _nextInstanceOfTime(hour, minute);

    debugPrint('📅 Notificación diaria programada para: $scheduledDate');

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel_v2',
          'Recordatorios diarios',
          channelDescription: 'Canal de recordatorios diarios',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          ticker: 'ticker',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> scheduleNotificationAt({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);

    debugPrint('🧪 Notificación test programada para: $scheduledDate');

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel_v2',
          'Pruebas',
          channelDescription: 'Canal para pruebas de notificaciones',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          ticker: 'ticker',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> scheduleDefaultDailyNotifications() async {
    await cancelDailyNotifications();

    await scheduleNotification(
      id: 1,
      title: 'Buenos días 🌞',
      body: 'Recuerda usar SeaBot y registrar cómo te sientes hoy.',
      hour: 9,
      minute: 0,
    );

    await scheduleNotification(
      id: 2,
      title: 'Pausa del día 🌿',
      body: '¿Cómo va tu día? Tómate un momento para entrar a la app.',
      hour: 13,
      minute: 0,
    );

    await scheduleNotification(
      id: 3,
      title: 'Cierre del día 🌙',
      body: 'Antes de dormir, puedes registrar tu estado emocional en SeaBot.',
      hour: 20,
      minute: 0,
    );
  }

  static Future<void> cancelDailyNotifications() async {
    await _notifications.cancel(1);
    await _notifications.cancel(2);
    await _notifications.cancel(3);
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
