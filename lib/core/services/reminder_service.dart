import 'dart:async';
import 'dart:developer';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  static ReceivedAction? initialAction;

  static final Completer<void> _initCompleter = Completer<void>();

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _ensureInitialized();

    log('All notifications cancelled');
  }

  // Cancel a specific notification
  static Future<void> cancelNotification(String id) async {
    await _ensureInitialized();
    log('Notification with id $id cancelled');
  }

  // Initialize the notification plugin
  static Future<void> init() async {
    if (_initCompleter.isCompleted) return; // Prevent re-initialization

    tz.initializeTimeZones();

    log('Notification plugin initialized successfully');
    _initCompleter.complete(); // Mark initialization as complete
  }

  static Future<void> initializeLocalNotifications() async {
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

    initialAction = await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: false);
  }

  // Notification action received handler
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    if (receivedAction.actionType == ActionType.SilentAction ||
        receivedAction.actionType == ActionType.SilentBackgroundAction) {
      // For background actions, log the action
      log('Background action received: ${receivedAction.id}');
      return;
    }

    // Handle foreground notification actions
    log('Notification action received: ${receivedAction.id}');
  }

  // Notification dismiss handler
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    log('Notification dismissed: ${receivedAction.id}');
  }

  // Notification created handler
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    log('Notification created: ${receivedNotification.id}');
  }

  // Notification displayed handler
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    log('Notification displayed: ${receivedNotification.id}');
  }

  // Schedule a notification
  static Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await _ensureInitialized();

    final tz.TZDateTime tzScheduledTime =
        tz.TZDateTime.from(scheduledTime, tz.local);

    log('Notification scheduled for $scheduledTime');
  }

  // Listen to notification events
  static Future<void> startListeningNotificationEvents() async {
    await _ensureInitialized();

    // Configure notification events
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );

    log('Notification event listeners set up successfully');
  }

  // Safe initialization guard
  static Future<void> _ensureInitialized() async {
    await _initCompleter.future;
  }
}
