import 'dart:async';
import 'dart:developer';
import 'dart:html' as html;

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  // Singleton-like pattern to ensure single initialization
  static final ReminderService _instance = ReminderService._internal();
  // Use a static Completer that can be reset if needed
  static Completer<void> _initCompleter = Completer<void>();
  factory ReminderService() => _instance;

  ReminderService._internal();

  static Future<void> init() async {
    // Reset the completer if it's already completed
    await _resetInitCompleter();

    try {
      // Initialize timezones for both web and mobile
      tz.initializeTimeZones();

      if (kIsWeb) {
        await _requestWebNotificationPermission();
      } else {
        await initializeLocalNotifications();
      }

      log('Notification service initialized successfully');

      // Complete the completer only if it's not already completed
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    } catch (e) {
      log('Error initializing notification service: $e');

      // Complete with error only if not already completed
      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(e);
      }
    }
  }

  static Future<void> initializeLocalNotifications() async {
    // Always initialize, not just for non-web
    await AwesomeNotifications().initialize(
        'resource://drawable/res_app_icon',
        [
          NotificationChannel(
              channelKey: 'alerts',
              channelName: 'Alerts',
              channelDescription: 'Notification tests as alerts',
              playSound: true,
              onlyAlertOnce: true,
              groupAlertBehavior: GroupAlertBehavior.Children,
              importance: NotificationImportance.High,
              defaultPrivacy: NotificationPrivacy.Private,
              defaultColor: Colors.deepPurple,
              ledColor: Colors.deepPurple)
        ],
        debug: true);

    // Request notification permissions explicitly
    await AwesomeNotifications().requestPermissionToSendNotifications();

    // Log initialization status
    log('Notifications initialized. Permission status: ${await AwesomeNotifications().isNotificationAllowed()}');
  }

  // Notification action received handler
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Handle notification action
  }

  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Handle notification dismissal
  }

  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    // Handle notification creation
  }

  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    // Handle notification display
  }

  // Register web background service
  static Future<void> registerBackgroundService() async {
    if (kIsWeb) {
      try {
        // Implement web background service registration
        log('Registering web background service');

        // Check if service worker is supported
        if (html.window.navigator.serviceWorker != null) {
          html.ServiceWorkerRegistration registration = await html
              .window.navigator.serviceWorker!
              .register('/reminder_worker.js');
          log('Service Worker registered: ${registration.scope}');
        } else {
          log('Service Worker not supported on this browser');
        }
      } catch (e) {
        log('Service Worker registration failed: $e');
      }
    }
  }

  static Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      // Ensure service is initialized
      await _ensureInitialized();

      // Normalize the scheduled time to the local timezone
      final localScheduledTime = scheduledTime.toLocal();
      final currentTime = DateTime.now().toLocal();

      log('🕒 Scheduling Time Verification:'
          '\n - Scheduled Time (Local): $localScheduledTime'
          '\n - Current Time (Local): $currentTime'
          '\n - Time Difference: ${localScheduledTime.difference(currentTime)}');

      // Ensure the scheduled time is in the future
      if (localScheduledTime.isBefore(currentTime)) {
        log('⚠️ Warning: Scheduled time is in the past. Skipping notification.');
        return;
      }

      // Enhanced logging
      log('🕒 Scheduling Notification Details:'
          '\n - Platform: ${kIsWeb ? "Web" : "Mobile/Desktop"}'
          '\n - ID: $id'
          '\n - Title: $title'
          '\n - Body: $body'
          '\n - Scheduled Time: $scheduledTime'
          '\n - Current Time: ${DateTime.now()}'
          '\n - Notification Allowed: ${await AwesomeNotifications().isNotificationAllowed()}');

      if (kIsWeb) {
        // Web-specific notification scheduling
        try {
          // Check if browser supports notifications
          if (!html.Notification.supported) {
            log('❌ Web notifications not supported in this browser');
            return;
          }

          final permission = await html.Notification.requestPermission();

          if (permission.toString() != 'granted') {
            log('Web Notification permissions not granted');
          }

          _scheduleWebNotification(
            id: id,
            title: title,
            body: body,
            scheduledTime: localScheduledTime,
          );
          log('✅ Web notification scheduled successfully');
        } catch (e, stackTrace) {
          log('❌ Web notification scheduling error: $e',
              stackTrace: stackTrace);
        }
      } else {
        // Mobile/Desktop notification scheduling using Awesome Notifications
        try {
          final tz.TZDateTime tzScheduledTime =
              tz.TZDateTime.from(localScheduledTime, tz.local);

          // Check notification permission before scheduling
          bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
          if (!isAllowed) {
            log('❌ Notifications not allowed. Requesting permission...');
            await AwesomeNotifications().requestPermissionToSendNotifications(
              permissions: NotificationPermission.values,
            );
            isAllowed = await AwesomeNotifications().isNotificationAllowed();
          }

          if (isAllowed) {
            await AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: id.hashCode,
                channelKey: 'alerts',
                title: title,
                body: body,
              ),
              schedule: NotificationCalendar.fromDate(
                date: tzScheduledTime,
                allowWhileIdle: true,
                preciseAlarm: true,
              ),
            );

            log('✅ Mobile notification scheduled successfully for $tzScheduledTime');
          } else {
            log('❌ Notification permission still not granted');
          }
        } catch (e, stackTrace) {
          log('❌ Mobile notification scheduling error: $e',
              stackTrace: stackTrace);
        }
      }
    } catch (e, stackTrace) {
      log('❌ Error in scheduleNotification: $e', stackTrace: stackTrace);
    }
  }

  static Future<void> startListeningNotificationEvents() async {
    await _ensureInitialized();

    if (kIsWeb) {
      // Web-specific event listening (if needed)
      log('Web notification event listener initialized');
    } else {
      // Configure notification events
      AwesomeNotifications().setListeners(
        onActionReceivedMethod: onActionReceivedMethod,
        onNotificationCreatedMethod: onNotificationCreatedMethod,
        onNotificationDisplayedMethod: onNotificationDisplayedMethod,
        onDismissActionReceivedMethod: onDismissActionReceivedMethod,
      );

      log('Notification event listeners set up successfully');
    }
  }

  static Future<void> _ensureInitialized() async {
    try {
      // If not completed, wait for initialization
      if (!_initCompleter.isCompleted) {
        await _initCompleter.future;
      }
    } catch (e) {
      log('Initialization error: $e');
      // Attempt to reinitialize if previous init failed
      await init();
    }
  }

  static Future<void> _requestWebNotificationPermission() async {
    if (html.Notification.supported) {
      try {
        final permission = await html.Notification.requestPermission();

        if (permission.toString() != 'granted') {
          log('Web Notification permissions not granted');
        }

        // Complete only if not already completed
        if (!_initCompleter.isCompleted) {
          _initCompleter.complete();
        }
      } catch (e) {
        log('Error requesting web notification permission: $e');

        // Complete with error only if not already completed
        if (!_initCompleter.isCompleted) {
          _initCompleter.completeError(e);
        }
      }
    } else {
      log('Web notifications not supported');

      // Complete only if not already completed
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    }
  }

  static Future<void> _resetInitCompleter() async {
    if (_initCompleter.isCompleted) {
      _initCompleter = Completer<void>();
    }
  }

  static void _scheduleWebNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) {
    // Calculate delay in milliseconds using UTC
    final now = DateTime.now().toUtc();
    final delay = scheduledTime.toUtc().difference(now);

    log('🕒 Web Notification Scheduling Details:'
        '\n - Delay: $delay'
        '\n - Current Time (UTC): $now'
        '\n - Scheduled Time (UTC): ${scheduledTime.toUtc()}');

    // Ensure delay is positive
    if (delay.isNegative) {
      log('❌ Scheduled time is in the past. Skipping web notification.');
      return;
    }

    // Use Timer for precise scheduling
    Timer(delay, () {
      try {
        // Create and show the notification
        final notification = html.Notification(
          title,
          body: body,
          // You can add more options like icon if needed
        );

        log('✅ Web notification triggered successfully');

        // Optional: Add click event handler
        notification.onClick.listen((_) {
          log('📣 Web notification clicked');
          // Add any click handling logic here
        });
      } catch (e) {
        log('❌ Error showing web notification: $e');
      }
    });
  }
}
