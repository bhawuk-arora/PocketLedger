import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Cheeky Punjabi reminder messages
  static const List<String> _reminderMessages = [
    'Oye Bhawuk! Aaj ka kharcha daala ki nahi? 🔥',
    'Paaji, kharcha likh le warna bhul jaayega 📝',
    'Bhai wallet ro rha hai... hisaab toh laga 😭',
    'Kiddan? Aaj kithe udaaye paise? Daal de! 💸',
    'Oye hoye! Kharcha track kar, nahi toh bappu nu das denge 👀',
    'Raat ho gayi, aaj ka nuqsaan report daal paaji 🌙',
    'Sat Sri Akaal! Kharcha likheya ki nahi aaj? ✍️',
    'Tera wallet bol rha — mera hisaab laga de! 💰',
    'Chal bhai, 2 minute kharcha daal ke soja 😴',
    'Daily kharcha = monthly surprise se bachao 🛡️',
  ];

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  /// Schedule a daily reminder at the given hour and minute
  Future<void> scheduleDailyReminder({int hour = 21, int minute = 0}) async {
    if (!_initialized) await initialize();

    // Cancel any existing reminder
    await cancelReminder();

    // Pick a random cheeky message
    final message = _reminderMessages[Random().nextInt(_reminderMessages.length)];

    await _plugin.zonedSchedule(
      0, // notification ID
      "Bhawuk's Kharcha 🔥",
      message,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Kharcha Reminder',
          channelDescription: 'Reminds you to log your daily expenses',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFFF6B35),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancel the daily reminder
  Future<void> cancelReminder() async {
    await _plugin.cancel(0);
  }

  /// Show an instant test notification
  Future<void> showTestNotification() async {
    if (!_initialized) await initialize();

    final message = _reminderMessages[Random().nextInt(_reminderMessages.length)];

    await _plugin.show(
      99, // test notification ID
      "Bhawuk's Kharcha 🔥",
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Kharcha Reminder',
          channelDescription: 'Reminds you to log your daily expenses',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFFF6B35),
        ),
      ),
    );
  }

  /// Check if reminder is currently scheduled
  Future<bool> isReminderScheduled() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.any((n) => n.id == 0);
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
