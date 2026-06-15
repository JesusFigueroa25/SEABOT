import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class DailyNotificationScheduleResult {
  DailyNotificationScheduleResult({
    required this.success,
    required this.permissionGranted,
    required this.alreadyValid,
    required this.scheduled,
    required Set<int> pendingIds,
    required Set<int> missingIds,
    this.errorMessage,
  }) : pendingIds = Set.unmodifiable(pendingIds),
       missingIds = Set.unmodifiable(missingIds);

  final bool success;
  final bool permissionGranted;
  final bool alreadyValid;
  final bool scheduled;
  final Set<int> pendingIds;
  final Set<int> missingIds;
  final String? errorMessage;
}

class _DailyReminder {
  const _DailyReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
  });

  final int id;
  final String title;
  final String body;
  final int hour;
  final int minute;
}

class _DailyPendingValidation {
  _DailyPendingValidation({
    required Set<int> pendingIds,
    required Set<int> missingIds,
    this.errorMessage,
  }) : pendingIds = Set.unmodifiable(pendingIds),
       missingIds = Set.unmodifiable(missingIds);

  final Set<int> pendingIds;
  final Set<int> missingIds;
  final String? errorMessage;
}

class NotificationService {
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const int _quickTestNotificationId = 1001;
  static const int _scheduledTestNotificationId = 1002;
  static const int _dailyChannelDiagnosticNotificationId = 1003;
  static const String _testNotificationScheduledAtKey =
      'test_notification_scheduled_at';
  static const String _dailyChannelId = 'daily_channel_v2';
  static const String _dailyChannelName = 'Recordatorios diarios';
  static const String _testChannelId = 'test_channel_v2';
  static const String _testChannelName = 'Pruebas';
  static const AndroidScheduleMode _dailyScheduleMode =
      AndroidScheduleMode.inexactAllowWhileIdle;
  static const Set<int> _dailyNotificationIds = <int>{1, 2, 3, 4, 5, 6, 7, 8, 9};
  static const List<_DailyReminder> _dailyReminders = <_DailyReminder>[
    _DailyReminder(
      id: 1,
      title: 'Buenos días 🌞',
      body: 'Empieza tu día con SeaBot y registra cómo te sientes.',
      hour: 9,
      minute: 0,
    ),
    _DailyReminder(
      id: 2,
      title: 'Pausa del día 🌿',
      body: 'Tómate un momento para revisar cómo va tu día con SeaBot.',
      hour: 13,
      minute: 0,
    ),
    _DailyReminder(
      id: 3,
      title: 'Prueba Tablet 1 🙎',
      body: 'Prueba ',
      hour: 16,
      minute: 05,
    ),
    _DailyReminder(
      id: 4,
      title: 'Prueba Tablet 2 🙎',
      body: 'Prueba',
      hour: 16,
      minute: 10,
    ),

    _DailyReminder(
      id: 5,
      title: 'Prueba Tablet 3 🙎',
      body: 'Prueba',
      hour: 16,
      minute: 15,
    ),

    _DailyReminder(
      id: 6,
      title: 'Prueba Tablet 4 🙎',
      body: 'Prueba',
      hour: 16,
      minute: 20,
    ),

    _DailyReminder(
      id: 7,
      title: 'Prueba Tablet 5 🙎',
      body: 'Prueba',
      hour: 16,
      minute: 25,
    ),

    _DailyReminder(
      id: 8,
      title: 'Cierre de la tarde 🌙',
      body: 'Antes de terminar la tarde, puedes conversar un momento con SeaBot.',
      hour: 16,
      minute: 0,
    ),
    _DailyReminder(
      id: 9,
      title: 'Pausa de la noche 🌤️',
      body: 'Antes de dormir, puedes registrar tu estado emocional en SeaBot.',
      hour: 20,
      minute: 0,
    ),
  ];

  static const NotificationDetails _dailyNotificationDetails =
      NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannelId,
          _dailyChannelName,
          channelDescription: 'Canal de recordatorios diarios',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          ticker: 'ticker',
        ),
        iOS: DarwinNotificationDetails(),
      );

  static const NotificationDetails _testNotificationDetails =
      NotificationDetails(
        android: AndroidNotificationDetails(
          _testChannelId,
          _testChannelName,
          channelDescription: 'Canal para pruebas de notificaciones',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          ticker: 'ticker',
        ),
        iOS: DarwinNotificationDetails(),
      );

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static void _log(String message) {
    debugPrint('[NotificationService] $message');
  }

  static String _formatIds(Iterable<int> ids) {
    final sortedIds = ids.toList()..sort();
    return sortedIds.toString();
  }

  static void _logPendingNotifications(
    List<PendingNotificationRequest> pendingRequests,
    String context,
  ) {
    final summary = pendingRequests
        .map((request) => '${request.id}:${request.title ?? ''}')
        .join(', ');
    _log(
      'Pending notifications $context: count=${pendingRequests.length}, '
      'items=[$summary]',
    );
  }

  static Future<_DailyPendingValidation> _validateDailyNotificationsPending({
    required String context,
  }) async {
    try {
      final pendingRequests = await _notifications
          .pendingNotificationRequests();
      _logPendingNotifications(pendingRequests, context);

      final pendingDailyIds = pendingRequests
          .where((request) => _dailyNotificationIds.contains(request.id))
          .map((request) => request.id)
          .toSet();
      final missingDailyIds = _dailyNotificationIds
          .where((id) => !pendingDailyIds.contains(id))
          .toSet();

      _log(
        'Validacion diaria $context: pendingDailyIds='
        '${_formatIds(pendingDailyIds)}, missingDailyIds='
        '${_formatIds(missingDailyIds)}',
      );

      return _DailyPendingValidation(
        pendingIds: pendingDailyIds,
        missingIds: missingDailyIds,
      );
    } on PlatformException catch (error, stackTrace) {
      _log(
        'PlatformException al consultar pending notifications $context: '
        'code=${error.code}, message=${error.message}, details=${error.details}',
      );
      debugPrintStack(stackTrace: stackTrace);

      return _DailyPendingValidation(
        pendingIds: const <int>{},
        missingIds: _dailyNotificationIds,
        errorMessage:
            'No se pudo validar la lista de notificaciones pendientes',
      );
    } catch (error, stackTrace) {
      _log('Error al consultar pending notifications $context: $error');
      debugPrintStack(stackTrace: stackTrace);

      return _DailyPendingValidation(
        pendingIds: const <int>{},
        missingIds: _dailyNotificationIds,
        errorMessage:
            'No se pudo validar la lista de notificaciones pendientes',
      );
    }
  }

  static Future<bool> _zonedScheduleWithDiagnostics({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required AndroidScheduleMode androidScheduleMode,
    required String channelId,
    required String diagnosticLabel,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    _log(
      'Programando $diagnosticLabel: id=$id, channel=$channelId, '
      'mode=$androidScheduleMode, timezone=${tz.local.name}, '
      'scheduledDate=$scheduledDate',
    );

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: androidScheduleMode,
        matchDateTimeComponents: matchDateTimeComponents,
      );
      return true;
    } on PlatformException catch (error, stackTrace) {
      _log(
        'PlatformException al programar $diagnosticLabel: id=$id, '
        'channel=$channelId, mode=$androidScheduleMode, code=${error.code}, '
        'message=${error.message}, details=${error.details}',
      );
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } catch (error, stackTrace) {
      _log(
        'Error al programar $diagnosticLabel: id=$id, channel=$channelId, '
        'mode=$androidScheduleMode, error=$error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _notifications.initialize(settings);

    tz.initializeTimeZones();

    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    _log(
      'Timezone local configurado: flutterTimezone=$currentTimeZone, '
      'tzLocal=${tz.local.name}',
    );
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

    if (androidPlugin == null) {
      _log(
        'Permiso de notificaciones: plugin Android no disponible, allowed=true',
      );
      return true;
    }

    try {
      final allowed = await androidPlugin.areNotificationsEnabled() ?? false;
      _log('Permiso de notificaciones: allowed=$allowed');
      return allowed;
    } on PlatformException catch (error, stackTrace) {
      _log(
        'PlatformException al consultar permiso de notificaciones: '
        'code=${error.code}, message=${error.message}, details=${error.details}',
      );
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  static Future<bool> requestNotificationPermission() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) {
      _log(
        'Solicitud de permiso de notificaciones: plugin Android no disponible, granted=true',
      );
      return true;
    }

    try {
      final before = await androidPlugin.areNotificationsEnabled() ?? false;
      _log('Permiso antes de solicitar: allowed=$before');

      if (before) return true;

      final granted = await androidPlugin.requestNotificationsPermission();
      _log('Solicitud de permiso de notificaciones: granted=$granted');

      await Future.delayed(const Duration(milliseconds: 700));

      final after = await androidPlugin.areNotificationsEnabled() ?? false;
      _log('Permiso despues de solicitar: allowed=$after');

      return granted == true || after;
    } on PlatformException catch (error, stackTrace) {
      _log(
        'PlatformException al solicitar permiso de notificaciones: '
        'code=${error.code}, message=${error.message}, details=${error.details}',
      );
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  static Future<DailyNotificationScheduleResult>
  syncNotificationPreferenceWithPermission({
    bool rescheduleIfEnabled = false,
  }) async {
    final preferenceEnabled = await getNotificationsPreference();
    _log(
      'Sincronizando preferencia de notificaciones: '
      'preferenceEnabled=$preferenceEnabled, '
      'rescheduleIfEnabled=$rescheduleIfEnabled',
    );

    if (!preferenceEnabled) {
      await cancelDailyNotifications();
      return DailyNotificationScheduleResult(
        success: false,
        permissionGranted: true,
        alreadyValid: false,
        scheduled: false,
        pendingIds: const <int>{},
        missingIds: _dailyNotificationIds,
      );
    }

    final permissionGranted = await areNotificationsAllowed();
    if (!permissionGranted) {
      await setNotificationsPreference(false);
      await cancelDailyNotifications();
      return DailyNotificationScheduleResult(
        success: false,
        permissionGranted: false,
        alreadyValid: false,
        scheduled: false,
        pendingIds: const <int>{},
        missingIds: _dailyNotificationIds,
        errorMessage: 'Permiso de notificaciones denegado',
      );
    }

    final validation = await _validateDailyNotificationsPending(
      context: 'antes de sincronizar',
    );
    if (validation.errorMessage != null) {
      await setNotificationsPreference(false);
      return DailyNotificationScheduleResult(
        success: false,
        permissionGranted: true,
        alreadyValid: false,
        scheduled: false,
        pendingIds: validation.pendingIds,
        missingIds: validation.missingIds,
        errorMessage: validation.errorMessage,
      );
    }

    if (validation.missingIds.isEmpty) {
      _log(
        'Notificaciones diarias ya pendientes. No se cancela ni reprograma.',
      );
      return DailyNotificationScheduleResult(
        success: true,
        permissionGranted: true,
        alreadyValid: true,
        scheduled: false,
        pendingIds: validation.pendingIds,
        missingIds: validation.missingIds,
      );
    }

    if (!rescheduleIfEnabled) {
      _log(
        'Faltan notificaciones diarias y no se solicito reprogramacion: '
        'missingDailyIds=${_formatIds(validation.missingIds)}',
      );
      await setNotificationsPreference(false);
      return DailyNotificationScheduleResult(
        success: false,
        permissionGranted: true,
        alreadyValid: false,
        scheduled: false,
        pendingIds: validation.pendingIds,
        missingIds: validation.missingIds,
        errorMessage: 'Faltan notificaciones diarias pendientes',
      );
    }

    return scheduleDefaultDailyNotifications(force: false);
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

    try {
      await _notifications.show(0, title, body, details);
    } on PlatformException catch (error, stackTrace) {
      _log(
        'PlatformException al mostrar notificacion instantanea: '
        'code=${error.code}, message=${error.message}, details=${error.details}',
      );
      debugPrintStack(stackTrace: stackTrace);
    } catch (error, stackTrace) {
      _log('Error al mostrar notificacion instantanea: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
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

    final wasPastOrNow =
        scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now);

    if (wasPastOrNow) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    _log(
      'Calculo nextInstanceOfTime: now=$now, '
      'requested=$hour:${minute.toString().padLeft(2, '0')}, '
      'wasPastOrNow=$wasPastOrNow, finalScheduledDate=$scheduledDate',
    );

    return scheduledDate;
  }

  static Future<void> restoreScheduledNotificationsIfEnabled() async {
    final result = await syncNotificationPreferenceWithPermission(
      rescheduleIfEnabled: true,
    );

    if (result.success) {
      _log(
        'Notificaciones restauradas o validadas automaticamente: '
        'alreadyValid=${result.alreadyValid}, scheduled=${result.scheduled}, '
        'pendingDailyIds=${_formatIds(result.pendingIds)}',
      );
    } else {
      _log(
        'Notificaciones no restauradas: permissionGranted='
        '${result.permissionGranted}, missingDailyIds='
        '${_formatIds(result.missingIds)}, error=${result.errorMessage}',
      );
    }
  }

  static Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final scheduledDate = _nextInstanceOfTime(hour, minute);

    _log(
      'Hora calculada para recordatorio diario: id=$id, hour=$hour, '
      'minute=$minute, scheduledDate=$scheduledDate',
    );

    return _zonedScheduleWithDiagnostics(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      details: _dailyNotificationDetails,
      androidScheduleMode: _dailyScheduleMode,
      channelId: _dailyChannelId,
      diagnosticLabel: 'recordatorio diario',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<bool> scheduleNotificationAt({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);

    _log('Hora calculada para notificacion test: $scheduledDate');

    return _zonedScheduleWithDiagnostics(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      details: _testNotificationDetails,
      androidScheduleMode: _dailyScheduleMode,
      channelId: _testChannelId,
      diagnosticLabel: 'notificacion test',
    );
  }

  static Future<DailyNotificationScheduleResult>
  scheduleDefaultDailyNotifications({bool force = true}) async {
    final permissionGranted = await areNotificationsAllowed();
    if (!permissionGranted) {
      return DailyNotificationScheduleResult(
        success: false,
        permissionGranted: false,
        alreadyValid: false,
        scheduled: false,
        pendingIds: const <int>{},
        missingIds: _dailyNotificationIds,
        errorMessage: 'Permiso de notificaciones denegado',
      );
    }

    _log(
      'Programacion diaria solicitada: force=$force, channel=$_dailyChannelId, '
      'mode=$_dailyScheduleMode, timezone=${tz.local.name}',
    );

    if (!force) {
      final validation = await _validateDailyNotificationsPending(
        context: 'antes de programar diarias',
      );
      if (validation.errorMessage != null) {
        await setNotificationsPreference(false);
        return DailyNotificationScheduleResult(
          success: false,
          permissionGranted: true,
          alreadyValid: false,
          scheduled: false,
          pendingIds: validation.pendingIds,
          missingIds: validation.missingIds,
          errorMessage: validation.errorMessage,
        );
      }

      if (validation.missingIds.isEmpty) {
        _log(
          'Programacion diaria omitida: pendingDailyIds='
          '${_formatIds(validation.pendingIds)}',
        );
        return DailyNotificationScheduleResult(
          success: true,
          permissionGranted: true,
          alreadyValid: true,
          scheduled: false,
          pendingIds: validation.pendingIds,
          missingIds: validation.missingIds,
        );
      }

      _log(
        'Se reprograman diarias porque faltan IDs: '
        '${_formatIds(validation.missingIds)}',
      );
    }

    await cancelDailyNotifications();

    var scheduledAll = true;
    for (final reminder in _dailyReminders) {
      final scheduled = await scheduleNotification(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        hour: reminder.hour,
        minute: reminder.minute,
      );
      scheduledAll = scheduledAll && scheduled;
    }

    final validation = await _validateDailyNotificationsPending(
      context: 'despues de programar diarias',
    );
    final success =
        scheduledAll &&
        validation.errorMessage == null &&
        validation.missingIds.isEmpty;

    if (!success) {
      final errorMessage =
          validation.errorMessage ??
          'No quedaron pendientes todas las notificaciones diarias';
      _log(
        'Fallo controlado al programar diarias: scheduledAll=$scheduledAll, '
        'pendingDailyIds=${_formatIds(validation.pendingIds)}, '
        'missingDailyIds=${_formatIds(validation.missingIds)}, '
        'error=$errorMessage',
      );
      await cancelDailyNotifications();
      return DailyNotificationScheduleResult(
        success: false,
        permissionGranted: true,
        alreadyValid: false,
        scheduled: false,
        pendingIds: validation.pendingIds,
        missingIds: validation.missingIds,
        errorMessage: errorMessage,
      );
    }

    return DailyNotificationScheduleResult(
      success: true,
      permissionGranted: true,
      alreadyValid: false,
      scheduled: true,
      pendingIds: validation.pendingIds,
      missingIds: validation.missingIds,
    );
  }

  static Future<void> cancelDailyNotifications() async {
    _log(
      'Cancelando notificaciones diarias: ids=${_formatIds(_dailyNotificationIds)}',
    );
    for (final id in _dailyNotificationIds) {
      await _notifications.cancel(id);
    }
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  //Prueba
  static Future<bool> scheduleTestNotificationAfter({int seconds = 10}) async {
    final allowed = await areNotificationsAllowed();
    if (!allowed) return false;

    await _notifications.cancel(_quickTestNotificationId);

    final scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(seconds: seconds));

    return _zonedScheduleWithDiagnostics(
      id: _quickTestNotificationId,
      title: 'Prueba rápida de notificación 🧪',
      body:
          'Esta es una notificación de prueba programada en $seconds segundos.',
      scheduledDate: scheduledDate,
      details: _testNotificationDetails,
      androidScheduleMode: _dailyScheduleMode,
      channelId: _testChannelId,
      diagnosticLabel: 'prueba rapida QA',
    );
  }

  static Future<bool> scheduleTestNotificationAtFiveFifteen() async {
    final allowed = await areNotificationsAllowed();
    if (!allowed) return false;

    await _notifications.cancel(_scheduledTestNotificationId);

    final scheduledDate = _nextInstanceOfTime(17, 10);

    final scheduled = await _zonedScheduleWithDiagnostics(
      id: _scheduledTestNotificationId,
      title: 'Prueba programada de notificación 🧪',
      body: 'Esta es una notificación de prueba programada para las 5:10 PM.',
      scheduledDate: scheduledDate,
      details: _testNotificationDetails,
      androidScheduleMode: _dailyScheduleMode,
      channelId: _testChannelId,
      diagnosticLabel: 'prueba QA 5:10 PM',
    );

    if (scheduled) {
      await _saveTestNotificationScheduledAt(scheduledDate);
    }

    return scheduled;
  }

  static Future<bool> scheduleDailyChannelDiagnosticNotificationAfter({
    int seconds = 10,
  }) async {
    final allowed = await areNotificationsAllowed();
    if (!allowed) return false;

    await _notifications.cancel(_dailyChannelDiagnosticNotificationId);

    final scheduledDate = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(seconds: seconds));

    final scheduled = await _zonedScheduleWithDiagnostics(
      id: _dailyChannelDiagnosticNotificationId,
      title: 'Prueba de recordatorios diarios',
      body:
          'Si recibes esta notificación, el canal Recordatorios diarios funciona.',
      scheduledDate: scheduledDate,
      details: _dailyNotificationDetails,
      androidScheduleMode: _dailyScheduleMode,
      channelId: _dailyChannelId,
      diagnosticLabel: 'prueba del canal diario',
    );

    await _validateDailyNotificationsPending(
      context: 'despues de programar prueba del canal diario',
    );

    return scheduled;
  }

  static Future<void> _saveTestNotificationScheduledAt(
    tz.TZDateTime scheduledDate,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _testNotificationScheduledAtKey,
      scheduledDate.millisecondsSinceEpoch,
    );
  }

  static Future<void> clearTestNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_testNotificationScheduledAtKey);
  }

  static Future<bool> isTestNotificationPending() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_testNotificationScheduledAtKey);

    if (millis == null) return false;

    final scheduledDate = DateTime.fromMillisecondsSinceEpoch(millis);
    final now = DateTime.now();

    if (now.isAfter(scheduledDate)) {
      await clearTestNotificationPreference();
      return false;
    }

    return true;
  }

  static Future<void> cancelTestNotification() async {
    await _notifications.cancel(_quickTestNotificationId);
    await _notifications.cancel(_scheduledTestNotificationId);
    await clearTestNotificationPreference();
  }
}
