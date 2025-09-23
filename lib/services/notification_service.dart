//import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _initialized = true;
  }

  static Future<void> showDonationAlert({
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'donation_channel',
      'Donation Alerts',
      channelDescription: 'Notifications for new donations and updates',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  static Future<void> showExpiryAlert({
    required String itemName,
    required int daysUntilExpiry,
  }) async {
    await showDonationAlert(
      title: 'Item Expiring Soon!',
      body: '$itemName expires in $daysUntilExpiry days. Consider donating it!',
      payload: 'expiry_alert',
    );
  }

  static Future<void> showNewDonationAlert({
    required String restaurantName,
    required String itemName,
    required String quantity,
  }) async {
    await showDonationAlert(
      title: 'New Donation Available!',
      body: '$restaurantName has $quantity of $itemName available for donation.',
      payload: 'new_donation',
    );
  }

  static Future<void> showDonationClaimedAlert({
    required String ngoName,
    required String itemName,
  }) async {
    await showDonationAlert(
      title: 'Donation Claimed!',
      body: '$ngoName has claimed your donation of $itemName.',
      payload: 'donation_claimed',
    );
  }

  static Future<void> showImpactReport() async {
    await showDonationAlert(
      title: 'Monthly Impact Report',
      body: 'You\'ve helped reduce food waste by 1250kg this month!',
      payload: 'impact_report',
    );
  }

  // Demo notification for testing
  static Future<void> showDemoNotification() async {
    await showDonationAlert(
      title: 'Demo Notification',
      body: 'This is a test notification from WasteLess!',
      payload: 'demo',
    );
  }

  // Schedule notifications for demo purposes (simplified version)
  static Future<void> scheduleDemoNotifications() async {
    await initialize();

    // Schedule a notification for 5 seconds from now
    await _notifications.show(
      1,
      'New Donation Nearby!',
      'Fresh vegetables available at Green Garden Restaurant',
      const NotificationDetails(),
    );

    // Schedule another notification for 10 seconds from now
    await Future.delayed(const Duration(seconds: 5));
    await _notifications.show(
      2,
      'Item Expiring Soon',
      'Bread loaves will expire in 1 day. Consider donating!',
      const NotificationDetails(),
    );
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}
