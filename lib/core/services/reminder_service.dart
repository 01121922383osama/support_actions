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

  static Future<bool> isNotificationAllowed() async {
    try {
      if (kIsWeb) {
        final isSupported = html.Notification.supported;
        final currentPermission = html.Notification.permission.toString();

        log('🔔 Web Notification Permission Check:'
            '\n - Notifications Supported: $isSupported'
            '\n - Current Permission: $currentPermission'
            '\n - Detailed Status: ${_getWebNotificationStatus()}');

        return isSupported && currentPermission == 'granted';
      } else {
        return await AwesomeNotifications().isNotificationAllowed();
      }
    } catch (e) {
      log('❌ Error checking notification permission: $e');
      return false;
    }
  }

  // Notification action received handler
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    log('🔔 Notification Action Received:'
        '\n - Title: ${receivedAction.title}'
        '\n - Body: ${receivedAction.body}'
        '\n - ID: ${receivedAction.id}');
  }

  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    log('🔔 Notification Dismissed:'
        '\n - Title: ${receivedAction.title}'
        '\n - Body: ${receivedAction.body}');
  }

  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    log('🔔 Notification Created:'
        '\n - Title: ${receivedNotification.title}'
        '\n - Body: ${receivedNotification.body}');
  }

  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    log('🔔 Notification Displayed:'
        '\n - Title: ${receivedNotification.title}'
        '\n - Body: ${receivedNotification.body}');
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

  static Future<bool> requestNotificationPermission() async {
    try {
      if (kIsWeb) {
        log('🔔 Requesting Web Notification Permission...');
        final permission = await html.Notification.requestPermission();

        log('🔔 Web Notification Permission Result:'
            '\n - Permission: ${permission.toString()}'
            '\n - Detailed Status: ${_getWebNotificationStatus()}');

        return permission.toString() == 'granted';
      } else {
        return await AwesomeNotifications()
            .requestPermissionToSendNotifications(
          permissions: NotificationPermission.values,
        );
      }
    } catch (e) {
      log('❌ Error requesting notification permission: $e');
      return false;
    }
  }

  static Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      // Adjust the scheduled time by subtracting 2 hours
      final adjustedScheduledTime = scheduledTime.subtract(Duration(hours: 2));

      // Ensure service is initialized
      await _ensureInitialized();

      // Check and request notification permission if not granted
      bool isAllowed = await isNotificationAllowed();
      if (!isAllowed) {
        log('🔔 Notification permission not granted. Requesting...');
        isAllowed = await requestNotificationPermission();
      }

      if (!isAllowed) {
        log('❌ Failed to get notification permission');
        return;
      }

      // Use the adjusted scheduled time
      final localNow = DateTime.now();

      log('🕒 Precise Scheduling Time Verification:'
          '\n - Original Scheduled Time: $scheduledTime'
          '\n - Adjusted Scheduled Time: $adjustedScheduledTime'
          '\n - Current Time (Local): $localNow'
          '\n - Time Difference: ${adjustedScheduledTime.difference(localNow)}');

      // Ensure the adjusted scheduled time is in the future
      if (adjustedScheduledTime.isBefore(localNow)) {
        log('⚠️ Warning: Adjusted scheduled time is in the past. Skipping notification.');
        return;
      }

      log('🕒 Scheduling Notification Details:'
          '\n - ID: $id'
          '\n - Title: $title'
          '\n - Body: $body'
          '\n - Adjusted Scheduled Time: $adjustedScheduledTime'
          '\n - Current Time (Local): $localNow');

      if (kIsWeb) {
        await _scheduleWebNotification(
          id: id,
          title: title,
          body: body,
          scheduledTime: adjustedScheduledTime,
        );
      } else {
        await _scheduleMobileNotification(
          id: id,
          title: title,
          body: body,
          scheduledTime: adjustedScheduledTime,
        );
      }
    } catch (e, stackTrace) {
      log('❌ Notification Scheduling Error: $e',
          error: e, stackTrace: stackTrace);
    }
  }

  static Future<void> startListeningNotificationEvents() async {
    try {
      await _ensureInitialized();

      // Configure notification listeners
      AwesomeNotifications().setListeners(
        onActionReceivedMethod: onActionReceivedMethod,
        onDismissActionReceivedMethod: onDismissActionReceivedMethod,
        onNotificationCreatedMethod: onNotificationCreatedMethod,
        onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      );

      log('✅ Notification event listeners configured successfully');
    } catch (e) {
      log('❌ Error configuring notification listeners: $e');
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

  static String _getWebNotificationStatus() {
    if (!html.Notification.supported) return 'Not Supported';

    switch (html.Notification.permission.toString()) {
      case 'granted':
        return 'Allowed ✅';
      case 'denied':
        return 'Permanently Blocked ❌';
      case 'default':
        return 'Pending User Decision ❓';
      default:
        return 'Unknown Status';
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

  static Future<void> _scheduleMobileNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
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
        final tz.TZDateTime tzScheduledTime =
            tz.TZDateTime.from(scheduledTime, tz.local);

        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: id.hashCode,
            channelKey: 'alerts',
            title: title,
            body: body,
            wakeUpScreen: true,
            category: NotificationCategory.Reminder,
          ),
          schedule: NotificationCalendar.fromDate(date: tzScheduledTime),
        );

        log('✅ Mobile notification scheduled successfully');
      } else {
        log('❌ Notification permission still not granted');
      }
    } catch (e, stackTrace) {
      log('❌ Mobile Notification Scheduling Error: $e',
          error: e, stackTrace: stackTrace);
    }
  }

  static Future<void> _scheduleWebNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      // Web-specific notification scheduling
      if (!html.Notification.supported) {
        log('❌ Web notifications not supported in this browser');
        return;
      }

      final permission = await html.Notification.requestPermission();

      if (permission.toString() != 'granted') {
        log('❌ Web Notification permissions not granted');
        return;
      }

      // Calculate delay in milliseconds using local time
      final now = DateTime.now();
      final delay = scheduledTime.difference(now).inMilliseconds;

      log('🕒 Web Notification Scheduling Details:'
          '\n - Delay: $delay ms'
          '\n - Current Time (Local): $now'
          '\n - Scheduled Time (Local): $scheduledTime');

      // Ensure delay is positive
      if (delay > 0) {
        // Use Timer for precise scheduling
        Timer(Duration(milliseconds: delay), () {
          try {
            // Create and show the notification
            final notification = html.Notification(
              title,
              body: body,
              // Optional: Add icon if needed
              // icon: 'path/to/icon.png'
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

        log('✅ Web notification scheduled successfully');
      } else {
        log('⚠️ Web notification time is in the past');
      }
    } catch (e, stackTrace) {
      log('❌ Web Notification Scheduling Error: $e',
          error: e, stackTrace: stackTrace);
    }
  }
}
